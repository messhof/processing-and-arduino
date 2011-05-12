#include <Servo.h> //include servo library

//   PIN STUFF
const int chooseButtonPin = 0; //store the choose button pin # (analog)
const int queryButtonPin = 3; //store the choose button pin # (analog) //NEEDS CONNECTION
const int pointerServoPin = 9; //store the pointer servo pin # (digital)

const int knobPin = 2; //store the pressure pin # (analog)
const int debugLED = 13; //store the built in LED pin # (digital)
Servo pointerServo;  // create servo object to control a servo
const int servoMessageWaitTotal = 100; //delay so you don't send too many signals to the servo
int servoMessageDelay = 0; //delay counter

//leds
const int yellowLED = 10;
const int redLED = 11;
const int greenLED = 12;

//sounds
const int tonePin = 8;
const int blankSound = 150;
const int symbolSound = 30;
const int limbSound = 300;
const int correct = 0;
const int incorrect = 1;
const int error = 2;
const int winGame = 3;
const int start = 4;
const int showProgress = 5;
const int loseGame = 6;
const int showLives = 7;

//morse
const int dotLength = 25;
const int inputDotLength = 25 * 6;
const int waitTimeBetweenCharacters = 100;
const int userInputTimeUp = 1000;
String chosenLetterInMorse;

boolean sendDataFlag = false;
boolean acceptInput = false;

// GAME STUFF
int limbs; //how many limbs you have left
String secretWord; //the word you're guessing
String guessedWord; //what you've guessed so far
boolean ANALOG = false;
int chooseButtonPressedLength;
int chooseButtonNotPressedLength;

boolean someDataInput = false;
String chosenLetter = "";

// WORD STUFF
const int wordBankSize=6;
String wordBank[wordBankSize] = {
  "batty","krist","doves","euros","dukes","front"};
String alphabet = "9abcdefghijklmnopqrstuvwxyz_012345";
int base_three_alphabet[34];

void setup()
{
  Serial.begin(9600); //start serial communication
  pinMode(debugLED, OUTPUT);  //connect the built in arduino LED for debug stuff
  if(ANALOG)
  {
    pointerServo.attach(pointerServoPin);  // attaches the servo pin to the servo object
  }
  else
  {
    pinMode(yellowLED,OUTPUT);
    pinMode(redLED,OUTPUT);
    pinMode(greenLED,OUTPUT);
    pinMode(tonePin,OUTPUT);
  }
  pinMode(chooseButtonPin, INPUT); //connect the chooser pushbutton
  pinMode(queryButtonPin, INPUT); //connect the query pushbutton

  int i;
  for(i=0; i<34; i+=1)
  {
    Serial.println(String(i));
    String morse_string = get_morse_string_from_char(alphabet.charAt(i));
    Serial.println(morse_string);
    base_three_alphabet[i] = morse_string_to_base_three(morse_string);
  }
  randomSeed(analogRead(1));
  reset_game(); //reset game variables
}

//reset game variables
void reset_game()
{
  limbs = 5; //5 limbs to lose
  Serial.println("Hangman by Mark Essen, 2011");
  Serial.println("it's time to play some hangman!");
  secretWord = get_random_word(); //arduino picks a word for user to guess
  guessedWord = "_____"; //reset the correctly guessed letters
  //show_progress();//show how many limbs left and the letters guessed correctly
  chooseButtonPressedLength = 0;
  chooseButtonNotPressedLength = 0;
  chosenLetterInMorse = "";
  digitalWrite(redLED,LOW);
  digitalWrite(yellowLED,LOW);
  digitalWrite(greenLED,LOW);
  acceptInput = false;
  clear_input_data();
  play_melody(start);
}

//game loop
void loop()
{
  acceptInput = true;
  if(query_button_pressed())
  {
    show_progress();
  }
  if(ANALOG)
  {
    chosenLetter = get_letter_from_knob();
    point_dial_to_letter(chosenLetter);
  }
  else
  {
    sendDataFlag = false;
    if(acceptInput)
      update_input_data();
  }

  if( (ANALOG && choose_button_pressed() ) || sendDataFlag)
  {
    Serial.println("you guessed " + chosenLetter);
    if(is_letter_in_secret_word(chosenLetter))
    {
      reveal_letter_in_guessed_word(chosenLetter);
      if(!ANALOG)
        flash_correct();
    }
    else
    {
      if(!ANALOG)
        flash_incorrect();
      Serial.println(chosenLetter+" was not in the word!");
      lose_a_limb();
    }
    delay(100);
    if(check_lose_state())
    {
      play_melody(loseGame);
      delay(900);
      reset_game();
    }
    clear_input_data();
  }
  if(check_win_state())
  {
    play_melody(winGame);
    delay(100);
    flash_message(greenLED,guessedWord,900);
    delay(200);
    flash_message(greenLED,guessedWord,900);
    delay(200);
    flash_message(greenLED,guessedWord,900);
    delay(900);
    reset_game();
  }
}  
void clear_input_data()
{
  someDataInput = false;
  sendDataFlag = false;
  chooseButtonNotPressedLength = 0;
  chooseButtonPressedLength = 0;
  chosenLetterInMorse="";
  chosenLetter = "";
}
void play_melody(int track)
{
  switch(track)
  {
    case start:
    int i;
    for(i=0; i<10; i+=1)
    {
      delay(20);
      int LED = redLED;
      if(random(30)<20)
        if(random(10)<5)
          LED = greenLED;
        else
          LED = yellowLED;
      play_long(random(1000),100,LED);
    }
    break;
    
    case correct:
    play_long(350,200,greenLED);
    delay(75);
    play_long(500,100,greenLED);
    delay(50);
    play_long(575,150,greenLED);
    break;
    
    case showProgress:
    digitalWrite(yellowLED,HIGH);
    digitalWrite(redLED,HIGH);
    play_long(900,300,greenLED);
    digitalWrite(yellowLED,LOW);
    digitalWrite(redLED,LOW);
    delay(75);
    digitalWrite(yellowLED,HIGH);
    digitalWrite(redLED,HIGH);
    play_long(900,700,greenLED);
    digitalWrite(yellowLED,LOW);
    digitalWrite(redLED,LOW);
    break;
    
    case showLives:
    digitalWrite(yellowLED,HIGH);
    digitalWrite(redLED,HIGH);
    play_long(1000,150,greenLED);
    digitalWrite(yellowLED,LOW);
    digitalWrite(redLED,LOW);
    delay(75);
    digitalWrite(yellowLED,HIGH);
    digitalWrite(redLED,HIGH);
    play_long(1000,200,greenLED);
    digitalWrite(yellowLED,LOW);
    digitalWrite(redLED,LOW);
    break;
    
    case winGame:
    play_sweep(500,1000,500,greenLED);
    delay(75);
    play_sweep(600,1100,500,greenLED);
    delay(75);
    play_sweep(700,1200,500,greenLED);
    delay(200);
    play_sweep(2000,1000,300,greenLED);
    delay(200);
    play_sweep(2000,1000,300,greenLED);
    delay(200);
    play_sweep(2000,1000,300,greenLED);
    break;
    
    case loseGame:
    play_long(100,200,redLED);
    delay(75);
    play_long(50,1200,redLED);
    delay(75);
    play_long(25,2000,redLED);
    break;
     
    case incorrect:
    play_long(200,200,redLED);
    delay(75);
    play_long(25,1200,redLED);
    break;
    
    case error:
    play_long(20,1200,yellowLED);
    break;
  }
}
void play_long(int hz, int length, int LED)
{
  turn_on_led_and_note(LED,hz);
  delay(length);
  turn_off_led_and_note(LED);
}
void play_sweep(int sweepStart, int sweepEnd, int sweepLength, int LED)
{
  int i = sweepStart;
  boolean up = true;
  if(sweepStart>sweepEnd)
  {
    up = false;
    i = sweepEnd;
  }
  boolean done = false;
  while(!done)
  {
    turn_on_led_and_note(LED,i);
    int freqDiff = abs(sweepStart - sweepEnd);
    delay( sweepLength / freqDiff);
    if(up)
    {
       i+=1;
       if(i>=sweepEnd)
         done = true;
    }
    else
    {
      i-=1;
      if(i<=sweepStart)
        done =true;
    }
  }
  turn_off_led_and_note(LED);
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void update_input_data()
{
  
  if(choose_button_pressed())
  {
    chooseButtonPressedLength+=1;
    chooseButtonNotPressedLength = 0;
    someDataInput = true;
    turn_on_led_and_note(yellowLED,symbolSound);
  }
  else
  {
    chooseButtonNotPressedLength+=1;
    if(chooseButtonNotPressedLength==1)
    {
      turn_off_led_and_note(yellowLED);
      if(chooseButtonPressedLength > 0)
      {
        String c = "";
        if(chooseButtonPressedLength < inputDotLength)
        {
          c = ".";
        }
        else
        {
          c = "-";
        }
        chosenLetterInMorse += c;
        Serial.println("added " + c + " to " + chosenLetterInMorse);
      }
    }
    if(chooseButtonNotPressedLength > waitTimeBetweenCharacters * 10 && someDataInput )
      sendDataFlag = true;
      
    chooseButtonPressedLength = 0;
  }
  
  if(sendDataFlag)
    chosenLetter = get_letter_from_morse_string(chosenLetterInMorse);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
String get_letter_from_morse_string(String morse)
{
  int base_three_string = morse_string_to_base_three(morse);
  String letter = "error";
  int i;
  for(i=1; i<27; i+=1)
  {
    if(base_three_alphabet[i] == base_three_string)
      letter = alphabet.charAt(i);
  }
  if(letter.equals("error"))
  {
    Serial.println("error finding letter in lookup table");
    play_melody(error);
    clear_input_data();
    return "";
  }
  else
  {
    return letter;
  }
}

void flash_correct()
{
  Serial.println("correct!");
  play_melody(correct);
  //flash_message(greenLED,"s",0);
}

void flash_incorrect()
{
  Serial.println("incorrect!");
  play_melody(incorrect);
  //flash_message(redLED,"o",0);
}

String get_random_word()
{
  String randomWord = wordBank[round(random(wordBankSize))]; //grab a random word from
  //the wordbank
  //randomWord = "zzaae";
  Serial.println(">>the secret word is " + randomWord);
  return randomWord;
}

boolean is_letter_in_secret_word(String chosenLetter)
{
  String secretChecker = secretWord.replace(chosenLetter,"@"); //turns all instances of the
  //chosen letter into garbage
  if(secretChecker.equals(secretWord)) //checks for garbage
    return false;
  else
    return true;
}

void reveal_letter_in_guessed_word(String revealedLetter)
{
  boolean charsToReplace[5];//word length array of flags for replacing letters
  int i;
  for(i=0; i<5; i+=1)//loop through charsToReplace flag array
  {
    charsToReplace[i]=false; //set all flags to false
  }
  for(i=0; i<5; i+=1)//loop through secret word
  {
    String nthChar = secretWord.charAt(i);//look at nth char
    if(nthChar.equals(revealedLetter)) //see if it's the one chosen
      charsToReplace[i]=1; //flag the position for replacement in the guessed word
  }
  for(i=0; i<5; i+=1)//loop through guessed word
  {
    if(charsToReplace[i])//see if the position is flagged
    {
      guessedWord.setCharAt(i,revealedLetter.charAt(0)); //replace it with the revealed letter
    }
  }
  //  Serial.println(revealedLetter + " was in the word!");
}

void lose_a_limb()
{
  limbs-=1; //hack off a limb
  Serial.println("lost a limb!");
}

void point_dial_to_letter(String indicatedLetter)
{
  int val = alphabet.indexOf(indicatedLetter); //find the position of the
  //letter in the alphabet

  //Serial.println("found character at alphabet array index " + String(val));
  val = map(val,0, 31, 179, 25);// scale it to use it with the servo
  // (value between 0 and 180)
  servoMessageDelay+=1;
  if(servoMessageDelay > servoMessageWaitTotal)//if we've waited long enough for the
    //servo to deal with the last message
  {
    pointerServo.write(val); //tell the servo where to point
    servoMessageDelay = 0; //reset the servo message delay
  }
}

String get_letter_from_knob()
{
  int val = analogRead(knobPin);    // read the value from the sensor
  val = round(map(val,0,1023,1,26));
  String letter = String(alphabet.charAt(val)); // map it to the
  // alphabet string
  //if(!letter.equals(previousPressureLetter))Serial.println("picking... "+letter);
  //previousPressureLetter=letter;
  return letter;
}

boolean choose_button_pressed()
{
  if(analogRead(chooseButtonPin) > 1023 / 2)
    return true;
  else
    return false;
}

boolean query_button_pressed()
{
  if(analogRead(queryButtonPin) > 1023 / 2)
    return true;
  else
    return false;
}

void show_progress()
{
  acceptInput = false;
  if(ANALOG)
    show_progress_analog();
  else
    show_progress_digital();
}

void show_progress_digital()
{
  play_melody(showProgress);
  Serial.println("so far you have guessed " + guessedWord);
  flash_message(redLED,guessedWord,0);
  delay(200);
  play_melody(showLives);
  flash_message(yellowLED,String(limbs),limbSound);
  delay(200);
  //digitalWrite(greenLED,HIGH);
}

void flash_message(int LED, String message, int note)
{
  Serial.println("flashing " + message);
  String morseString;
  int i, w, n;
  n = symbolSound;
  if(note!=0) n = note;
  for(i=0; i< message.length(); i+=1)
  {
    morseString = get_morse_string_from_char( message.charAt(i) );
    if(morseString.equals(""))
    {
      flash_pin_symbol_tone(yellowLED,'-',blankSound);
    }
    else
    {
      for(w=0; w< morseString.length(); w+=1)
      {
        flash_pin_symbol_tone(greenLED,morseString.charAt(w),n);
      }
    }
    delay(waitTimeBetweenCharacters);
  }
  Serial.println("done flashing");
}

void flash_pin_symbol_tone(int LED, char c, int note)
{
  int length;
  length = 0;
  if(c=='-')
    length = dotLength*3;
  if(c=='.')
    length = dotLength;
   if(length>0)
   {
    turn_on_led_and_note(LED,note);
    delay(length);
    turn_off_led_and_note(LED);
    delay(waitTimeBetweenCharacters);
   }
}

void turn_on_led_and_note(int LED, int note)
{
  digitalWrite(LED,HIGH);
  tone(tonePin,note);
}

void turn_off_led_and_note(int LED)
{
  digitalWrite(LED,LOW);
  noTone(tonePin);
}

String get_morse_string_from_char(char letter)
{
  String morse;
  switch(letter)
  {

  case 'a': 
    morse = ".-   "; 
    break;
  case 'b': 
    morse = "-... "; 
    break;
  case 'c': 
    morse = "-.-. "; 
    break;
  case 'd': 
    morse = "-..  "; 
    break;
  case 'e': 
    morse = ".    "; 
    break;
  case 'f': 
    morse = "..-. "; 
    break;
  case 'g': 
    morse = "--.  "; 
    break;
  case 'h': 
    morse = ".... "; 
    break;
  case 'i': 
    morse = "..   "; 
    break;
  case 'j': 
    morse = ".--- "; 
    break;
  case 'k': 
    morse = "-.-  "; 
    break;
  case 'l': 
    morse = ".-.. "; 
    break;
  case 'm': 
    morse = "--   "; 
    break;
  case 'n': 
    morse = "-.   "; 
    break;
  case 'o': 
    morse = "---  "; 
    break;
  case 'p': 
    morse = ".--. "; 
    break;
  case 'q': 
    morse = "--.- "; 
    break;
  case 'r': 
    morse = ".-.  "; 
    break;
  case 's': 
    morse = "...  "; 
    break;
  case 't': 
    morse = "-    "; 
    break;
  case 'u': 
    morse = "..-  "; 
    break;
  case 'v': 
    morse = "...- "; 
    break;
  case 'w': 
    morse = ".--  "; 
    break;
  case 'x': 
    morse = "-..- "; 
    break;
  case 'y': 
    morse = "-.-- "; 
    break;
  case 'z': 
    morse = "--.. "; 
    break;

  case '0': 
    morse = "-----"; 
    break;
  case '1': 
    morse = ".----"; 
    break;
  case '2': 
    morse = "..---"; 
    break;
  case '3': 
    morse = "...--"; 
    break;
  case '4': 
    morse = "....-"; 
    break;
  case '5': 
    morse = "....."; 
    break;

  case '_': 
    morse = ""; 
    break;

  case '9': 
    morse = ".......--"; 
    break;

  default: 
    morse = ".........."; 
    Serial.println("error, no morse found for char "+String(letter)); 
    break;
  }
  return morse;
}

int morse_string_to_base_three(String morse)
{
  int i;
  int base_three = 0;
  for(i=0; i<5; i+=1)
  {
    if(morse.charAt(i)=='.')
      base_three += 1 * pow(3,i);
    if(morse.charAt(i)=='-')
      base_three += 2 * pow(3,i);
    if(morse.charAt(i)== ' ')
      base_three += 0 * pow(3,i);
  }
  Serial.println("generated base three int of "+String(base_three));
  return base_three;
}

void wait()
{
  delay(100);
}

void show_progress_analog()
{
  Serial.println("so far you have guessed " + guessedWord);
  int i;
  int timestamp;
  long wait = 10000;
  for(i=0; i<5; i+=1)
  {
    String let;
    let = String(guessedWord.charAt(i));
    Serial.println(String(i) + "st char is " + let);
    timestamp = 0;
    while(timestamp<wait)
    {
      point_dial_to_letter("9"); //clear
      timestamp+=1;
    }
    timestamp =0;
    while(timestamp<wait)
    {
      point_dial_to_letter(let);
      timestamp+=1;
    }
  }
  Serial.println("you have " + String(limbs) + " limb(s) remaining...");

  timestamp = 0;
  while(timestamp<wait)
  {
    point_dial_to_letter("9"); //clear
    timestamp+=1;
  }
  timestamp = 0;
  while(timestamp<wait)
  {
    point_dial_to_letter(String(limbs)); //set

    timestamp+=1;
  } 
}

boolean check_win_state()
{
  if(guessedWord.equals(secretWord))
  {
    Serial.println("you win! \n\n");
    return true;
  }
  else
    return false;
}

boolean check_lose_state()
{
  if(limbs<1)
  {
    Serial.println("game over!");
    return true;
  }
  else
  {
    return false;
  }
}

