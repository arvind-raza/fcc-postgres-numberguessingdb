#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# Prompt user for username
get_username() {
  echo -e "\nEnter your username:"
  read USERNAME

  if [[ ${#USERNAME} -gt 22 ]]; then
    get_username
  fi
}

get_username

# Check if user exists in the database
USER_INFO=$($PSQL "SELECT user_info.user_id, COUNT(games.game_id), MIN(games.num_guesses) FROM user_info LEFT JOIN games ON user_info.user_id = games.user_id WHERE username='$USERNAME' GROUP BY user_info.user_id")

if [[ -z $USER_INFO ]]; then
  INSERT_USER_INFO_RESULT=$($PSQL "INSERT INTO user_info (username) VALUES ('$USERNAME')")
  USER_ID=$($PSQL "SELECT user_id FROM user_info WHERE username = '$USERNAME'")
  echo -e "\nWelcome, $USERNAME! It looks like this is your first time here."
else
  IFS='|' read -r USER_ID GAMES_PLAYED BEST_GAME <<< "$USER_INFO"
  GAMES_PLAYED=${GAMES_PLAYED:-0} # Default to 0 if null
  BEST_GAME=${BEST_GAME:-"N/A"}   # Default to "N/A" if user has not completed any games
  GAMES_WORD=$([[ $GAMES_PLAYED -eq 1 ]] && echo "game" || echo "games")
  GUESSES_WORD=$([[ $BEST_GAME -eq 1 ]] && echo "guess" || echo "guesses")
  echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

TRIES=1

# Function for guessing the number
guess_number() {
  read GUESS

  while [[ ! $GUESS =~ ^[0-9]+$ || $GUESS -ne $SECRET_NUMBER ]]; do
    if [[ ! $GUESS =~ ^[0-9]+$ ]]; then
      echo -e "\nThat is not an integer, guess again:"
    elif [[ $GUESS -gt $SECRET_NUMBER ]]; then
      echo -e "\nIt's lower than that, guess again:"
    else
      echo -e "\nIt's higher than that, guess again:"
    fi
    ((TRIES++))
    read GUESS
  done
}

echo -e "\nGuess the secret number between 1 and 1000:"
guess_number

# Insert game results
INSERT_GAMES_RESULT=$($PSQL "INSERT INTO games (user_id, num_guesses) VALUES ($USER_ID, $TRIES)")

TRIES_WORD=$([[ $TRIES -eq 1 ]] && echo "try" || echo "tries")
echo -e "\nYou guessed it in $TRIES tries. The secret number was $SECRET_NUMBER. Nice job!"
