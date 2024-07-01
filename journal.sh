#!/bin/bash

SETUP_FLAG="--setup"
JOURNAL_PATH=""
GPG_KEY=""
MESSAGE_KEYS="To change which GPG key is used by default edit ~/.journal"
FILE_TO_ENCRYPT=""

function invalidInput()
{
	echo "Error: invalid input, terminating script"
}

set -e # exit on first command error

if [[ "$1" == "$SETUP_FLAG" && "$#" -eq 1 ]] # test if setup flag is used
then
	read -p "Use an existing GPG Key? (y/n): " HASKEY

	if [[ "$HASKEY" == "y" || "$HASKEY" == "Y" ]]
	then
		echo "What is the email tied to the GPG key?"
		read GPG_KEY
		echo "GPG_KEY = \"$GPG_KEY\"" > ~/.journal 
		echo "$MESSAGE_KEYS"
	elif [[ "$HASKEY" == "n" || "$HASKEY" == "N" ]]
	then
		gpg --full-gen-key
		GPG_KEY=$(gpg --list-keys | tail -3 | grep -o "<\S*>$" | sed "s/<//g; s/>//g")
		echo "GPG_KEY = \"$GPG_KEY\"" > ~/.journal 
		echo "$MESSAGE_KEYS"
	else
		invalidInput
		exit 1
	fi

	echo "Provide an existing or new file path to directory for journal files: "
	read JOURNAL_PATH

	if [[ "$JOURNAL_PATH" == "" ]]
	then
		echo "No journal directory supplied, creating default directory at ~/.myjournal"
		mkdir ~/.myjournal
		JOURNAL_PATH="$HOME/.myjournal"
	elif [[ ! -d "$JOURNAL_PATH" ]]
	then
		read -p "Directory does not exist, would you like to create it? (y/n): " MAKE_DIR
		if [[ "$MAKE_DIR" == "y" || "$MAKE_DIR" == "Y" ]]
		then
			mkdir $JOURNAL_PATH
		elif [[ "$MAKE_DIR" == "n" || "$MAKE_DIR" == "N" ]]
		then
			echo "Using the directory default instead..."
			mkdir ~/.myjournal
			JOURNAL_PATH="$HOME/.myjournal"
		else
			invalidInput
			exit 1
		fi
	fi

	echo "JOURNAL_PATH = \"$JOURNAL_PATH\"" >> ~/.journal
	echo "To change the directory used by default edit ~/.journal"
elif [[ $# -eq 0 ]] # test if 0 arguments passed
then
	if [[ ! -e ~/.journal ]]
	then
		echo "Error: no valid config file; run 'journal --setup'"
		exit 2
	fi

	read -p "Would you like to encrypt or decrypt a file? (e/d): " ENC_OR_DEC
	GPG_KEY=$(grep GPG_KEY ~/.journal | sed "s/GPG_KEY = //g; s/\"//g")
	JOURNAL_PATH=$(grep JOURNAL_PATH ~/.journal | sed "s/JOURNAL_PATH = //g; s/\"//g")

	if [[ "$ENC_OR_DEC" == "e" || "$ENC_OR_DEC" == "E" ]]
	then
		FILE_TO_ENCRYPT=$(date +"%m-%d-%Y")
		JOURNAL_DATE=$(date +"%A %B %d, %Y%n%H:%M:%S")
		echo "$JOURNAL_DATE" > $JOURNAL_PATH/$FILE_TO_ENCRYPT
		vim $JOURNAL_PATH/$FILE_TO_ENCRYPT
		gpg -r "$GPG_KEY" -e "$JOURNAL_PATH/$FILE_TO_ENCRYPT"
		shred -zvun 4 "$JOURNAL_PATH/$FILE_TO_ENCRYPT"
		echo "File was encrypted at $JOURNAL_PATH/$FILE_TO_ENCRYPT.gpg"
	elif [[ "$ENC_OR_DEC" == "d" || "$ENC_OR_DEC" == "D" ]] 
	then
		echo "Filename to decrypt (without .gpg file extension):"
		read FILE_TO_DECRYPT
		gpg -d "$JOURNAL_PATH/$FILE_TO_DECRYPT.gpg" > $JOURNAL_PATH/$FILE_TO_DECRYPT
	       	less "$JOURNAL_PATH/$FILE_TO_DECRYPT"
		shred -zvun 4 "$JOURNAL_PATH/$FILE_TO_DECRYPT"
	else
		invalidInput
		exit 1
	fi
else
	invalidInput
	exit 1
fi







