#include <Servo.h> //include servo library

//   PIN STUFF
const int chooseButtonPin = 3; //store the choose button pin # (analog)
const int queryButtonPin = 0; //store the choose button pin # (analog) //NEEDS CONNECTION
const int pointerServoPin = 9; //store the pointer servo pin # (digital)
const int knobPin = 2; //store the pressure pin # (analog)
const int debugLED = 13; //store the built in LED pin # (digital)
Servo pointerServo;  // create servo object to control a servo 
const int servoMessageWaitTotal = 100; //delay so you don't send too many signals to the servo
int servoMessageDelay = 0; //delay counter
//String previousPressureLetter = ".";

// GAME STUFF
int limbs; //how many limbs you have left
String secretWord; //the word you're guessing
String guessedWord; //what you've guessed so far
boolean ANALOG = true;

// WORD STUFF
const int wordBankSize=6;
String wordBank[wordBankSize] = {"batty","candy","doves","euros","dukes","front"};
String alphabet = "9abcdefghijklmnopqrstuvwxyz-012345"; 
 
void setup() 
{ 
  Serial.begin(9600); //start serial communication
  if(ANALOG)
  {
    pointerServo.attach(pointerServoPin);  // attaches the servo pin to the servo object
  }
  pinMode(debugLED, OUTPUT);  //connect the built in arduino LED for debug stuff
  pinMode(chooseButtonPin, INPUT); //connect the chooser pushbutton
  pinMode(queryButtonPin, INPUT); //connect the query pushbutton
  reset_game(); //reset game variables
}

//reset game variables
void reset_game()
{
  limbs = 5; //5 limbs to lose
  Serial.println("Hangman by Mark Essen, 2011");
  Serial.println("it's time to play some hangman!");
  secretWord = get_random_word(); //arduino picks a word for user to guess
  guessedWord = "-----"; //reset the correctly guessed letters
  show_progress();//show how many limbs left and the letters guessed correctly
}

//game loop
void loop() 
{
     if(query_button_pressed())
     {
       show_progress();
     }
     if(ANALOG)
     { 
       String chosenLetter = get_letter_from_knob();
       point_dial_to_letter(chosenLetter); //tell the servo to point to the letter
     }
     
     if(choose_button_pressed())
     {
       //user selected a letter
       Serial.println("you guessed \"" + chosenLetter + "\"\n");
       if(is_letter_in_secret_word(chosenLetter))
         reveal_letter_in_guessed_word(chosenLetter);
       else
       {
         Serial.println(chosenLetter+" was not in the word!");
         lose_a_limb();
       }
       delay(2000);
       show_progress();
       if(check_lose_state())
       {
          delay(900);
          reset_game();
       }
     } 
   if(check_win_state())
       {
         delay(900);
         reset_game(); 
       }
}   

//grab a random word from the wordbank
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

//change guessed word to reveal letter
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

//point the dial towards the letter on the gauge
void point_dial_to_letter(String indicatedLetter)
{
  int val = alphabet.indexOf(indicatedLetter); //find the position of the 
                                               //letter in the alphabet
  
    //Serial.println("found character at alphabet array index " + String(val));
  val = map(val,0, 31, 179, 25);// scale it to use it with the servo 
                                  // (value between 0 and 180) 
  servoMessageDelay+=1;
  if(servoMessageDelay>servoMessageWaitTotal)//if we've waited long enough for the
                           //servo to deal with the last message
  {
    pointerServo.write(val); //tell the servo where to point
    servoMessageDelay = 0; //reset the servo message delay
  }
}

//get the letter indicated by the pressure sensor
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

//check if the choose button is pressed
boolean choose_button_pressed()
{
 if(analogRead(chooseButtonPin) > 1023 / 2)
   return true;
  else
   return false;
}

//check if the query button is pressed
boolean query_button_pressed()
{
 if(analogRead(queryButtonPin) > 1023 / 2)
   return true;
  else
   return false;
}

void show_progress()
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
    Serial.println("game over!\n\n");
    return true;
  }
  else
  {
    return false;
  }
}
