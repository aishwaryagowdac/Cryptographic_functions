#!/bin/bash


#if the first argument is -sender, then implements the sender side code
if [ "$1" == "-sender" ]; then
	#If the number of arguments passed are not equal 7, then the script throws an error with the description
	if [ $# -ne 7 ]; then
		echo "ERROR channappaji.a" >&2
		echo "Incorrect Arguments passed: Expected input in the format: bash crypto.sh -sender r1.pub r2.pub r3.pub s1.priv plainttext_file zip_file" >&2
		echo "	r1.pub r2.pub and r3.pub: receiver's public keys" >&2
		echo "	s1.priv: sender's private key" >&2
		echo "	plaintext_file: file that has to be encrypted" >&2
		echo "	zip_file: output file name where you want the intermediate files to be zipped" >&2
	else
		#Genrating the symmetric key needed to encrypt the plaintext file  
		echo "Generating symmetric key...."
		openssl rand -base64 128 > symm.key
		echo "Symmetric key generated!"
		#encrypting the file
		echo "Encrypting the plaintext file..."
		if openssl enc -aes-256-cbc -pbkdf2 -e -in $6 -out file.enc -pass file:symm.key > /dev/null 2>&1; then
			echo "Plaintext file encrypted!"
			#siging the encrypted file
			echo "Signing the encrypted file..."
			if openssl dgst -sha256 -sign $5 -out file.enc.sign file.enc > /dev/null 2>&1; then
				echo "Plaintext file is now signed and encrypted!"
				#creating shared key inorder to encrypt the symmetric key for all the 3 receivers
				echo "Generating shared keys for all the 3 receivers..."
				if openssl pkeyutl -derive -inkey $5 -peerkey $2 -out shared_recv1.key > /dev/null 2>&1; then
					if openssl pkeyutl -derive -inkey $5 -peerkey $3 -out shared_recv2.key > /dev/null 2>&1; then
						if openssl pkeyutl -derive -inkey $5 -peerkey $4 -out shared_recv3.key > /dev/null 2>&1; then
							echo "Shared keys for all the 3 receivers generated!"
							#encrypting symmetric key using respective receiver's shared keys
							echo "Encrypting symmetric key using receiver's shared keys..."
							openssl enc -aes-256-cbc -pbkdf2 -e -in symm.key -out receiver1.priv_symm.enc -pass file:shared_recv1.key
							openssl enc -aes-256-cbc -pbkdf2 -e -in symm.key -out receiver2.priv_symm.enc -pass file:shared_recv2.key
							openssl enc -aes-256-cbc -pbkdf2 -e -in symm.key -out receiver3.priv_symm.enc -pass file:shared_recv3.key
							echo "Symmetric key encrypted for all the 3 receiver's shared keys!"
							#zip all the required files and name the file provided by argument
							echo "zipping all the required files..."
							zip -q $7 file.enc file.enc.sign receiver1.priv_symm.enc receiver2.priv_symm.enc receiver3.priv_symm.enc
							echo "All the files are zipped successfully and the zipped file is '$7.zip'"
							#deleting all the intermediate files
							rm symm.key file.enc file.enc.sign shared_recv1.key shared_recv2.key shared_recv3.key receiver1.priv_symm.enc receiver2.priv_symm.enc receiver3.priv_symm.enc 
						#Throws an error if the shared key for receiver 3 is not created
						else
							echo "ERROR channappaji.a" >&2
							echo "Failed to create shared key for receiver 3. Check if correct receiver's public key is provided" >&2
							rm symm.key file.enc file.enc.sign
							exit 1
						fi
					#Throws an error if the shared key for receiver 2 is not created
					else
						echo "ERROR channappaji.a" >&2
						echo "Failed to create shared key for receiver 2. Check if correct receiver's public key is provided" >&2
						rm symm.key file.enc file.enc.sign
						exit 1
					fi
				#Throws an error if the shared key for receiver 1 is not created
				else
					echo "ERROR channappaji.a" >&2
					echo "Failed to create shared key for receiver 1. Check if correct receiver's public key is provided" >&2
					rm symm.key file.enc file.enc.sign
					exit 1
				fi
			#Throws an error if the encrypted file could not be signed
			else
				echo "ERROR channappaji.a" >&2
				echo "Failed to sign the encrypted file. Check the sender's private key" >&2
				rm symm.key file.enc file.enc.sign
				exit 1
			fi
		#Throws an error if the the file encryption fails
		else
			echo "ERROR channappaji.a" >&2
			echo "Failed to encrypt the file. provide correct file name that has to be encrypted or check if the file is in the directory" >&2
			exit 1
		fi
	fi

#else if the first argument is -receiver, then implements the receiver side code
elif [ "$1" == "-receiver" ]; then
	#If the number of arguments passed are not equal 5, then the script throws an error with the description
	if [ $# -ne 5 ]; then
		echo "ERROR channappaji.a" >&2
		echo "Incorrect Arguments passed: Expected input in the format: bash crypto.sh -receiver r#.priv s.pub zip_file plainttext_file" >&2
		echo "	r#.priv: receiver's private keys" >&2
		echo "	s.pub: sender's public key" >&2
		echo "	zip_file: zipped output file generated after encryption" >&2
		echo "	plaintext_file: Final decrypted file" >&2
	else
		#unzipping the output file from sender"
		echo "unzipping the output from sender..."
		if unzip -q $4 > /dev/null 2>&1; then
			echo "files are unzipped!"
			#Verifying the signature to check if the files we received are authentic or not
			echo "verifying the signature..." 
			if openssl dgst -sha256 -verify $3 -signature file.enc.sign file.enc > /dev/null 2>&1; then
				echo "Signature verified successfully!"
				#Creating shared secret key 
				echo "creating shared secret key for the $2..."
				if openssl pkeyutl -derive -inkey $2 -peerkey $3 -out dec_shared.key > /dev/null 2>&1; then
					echo "shared secret key created!"
					#Decrypting symmetric key using generated shared key. For decrypting, it checks all the 3 receiver's symmetric encrytion key in if loop
					echo "Decrypting symmetric key for $2..."
					if ! openssl enc -aes-256-cbc -pbkdf2 -d -in receiver1.priv_symm.enc -out dec_symm.key -pass file:dec_shared.key > /dev/null 2>&1; then
						echo "Error channappaji.a" >&2
						echo "Attempting again with another symmetric encrypted key" >&2
						if ! openssl enc -aes-256-cbc -pbkdf2 -d -in receiver2.priv_symm.enc -out dec_symm.key -pass file:dec_shared.key > /dev/null 2>&1; then
							echo "Error channappaji.a" >&2
							echo "Attempting again with another symmetric encrypted key" >&2
							if ! openssl enc -aes-256-cbc -pbkdf2 -d -in receiver3.priv_symm.enc -out dec_symm.key -pass file:dec_shared.key > /dev/null 2>&1; then
								#if decryption failes, it exits out out loop throwing error
								echo "ERROR channappaji.a" >&2
								echo "Digital Envelope Decryption failed. private key povided cannot access any envelopes" >&2
								rm file.enc file.enc.sign receiver1.priv_symm.enc receiver2.priv_symm.enc receiver3.priv_symm.enc 
								exit 1
							#if the provided private key is receiver 3, then it decrypts the symmetriv key using r3
							else
								echo "Decrypted symmetric key for $2!"
								#Finally decrypting the encrypted file using symmetric key
								echo "Decrypting the file..."
								if openssl enc -aes-256-cbc -pbkdf2 -d -in file.enc -out $5 -pass file:dec_symm.key > /dev/null 2>&1; then
									echo "The file is successfully decrypted and plaintext file is saved in the name $5" 
									#Deleting all the intermediate files
									rm file.enc file.enc.sign dec_symm.key dec_shared.key receiver1.priv_symm.enc receiver2.priv_symm.enc receiver3.priv_symm.enc 
								else
									echo "ERROR channappaji.a" >&2
									echo "File could not be decrypted to plain text" >&2
									rm file.enc file.enc.sign dec_symm.key dec_shared.key receiver1.priv_symm.enc receiver2.priv_symm.enc receiver3.priv_symm.enc 
									exit 1
								fi
							fi
						#if the provided private key is receiver 2, then it decrypts the symmetriv key using r2
						else
							echo "Decrypted symmetric key for $2!"
							#Finally decrypting the encrypted file using symmetric key
							echo "Decrypting the file..."
							if openssl enc -aes-256-cbc -pbkdf2 -d -in file.enc -out $5 -pass file:dec_symm.key > /dev/null 2>&1; then
								echo "The file is successfully decrypted and plaintext file is saved in the name $5" 
								#Deleting all the intermediate files
								rm file.enc file.enc.sign dec_symm.key dec_shared.key receiver1.priv_symm.enc receiver2.priv_symm.enc receiver3.priv_symm.enc 
							else
								echo "ERROR channappaji.a" >&2
								echo "File could not be decrypted to plain text" >&2
								rm file.enc file.enc.sign dec_symm.key dec_shared.key receiver1.priv_symm.enc receiver2.priv_symm.enc receiver3.priv_symm.enc 
								exit 1
							fi
						fi
					#if the provided private key is receiver 1, then it decrypts the symmetriv key using r1
					else
						echo "Decrypted symmetric key for $2!"
						#Finally decrypting the encrypted file using symmetric key
						echo "Decrypting the file..."
						if openssl enc -aes-256-cbc -pbkdf2 -d -in file.enc -out $5 -pass file:dec_symm.key > /dev/null 2>&1; then
							echo "The file is successfully decrypted and plaintext file is saved in the name $5" 
							#Deleting all the intermediate files
							rm file.enc file.enc.sign dec_symm.key dec_shared.key receiver1.priv_symm.enc receiver2.priv_symm.enc receiver3.priv_symm.enc 
						#Throws an error if final file decryption fails
						else
							echo "ERROR channappaji.a" >&2
							echo "File could not be decrypted to plain text" >&2
							rm file.enc file.enc.sign dec_symm.key dec_shared.key receiver1.priv_symm.enc receiver2.priv_symm.enc receiver3.priv_symm.enc 
							exit 1
						fi
					fi
				#if shared secret generation fails, it exits out of the loop throwing error
				else
					echo "ERROR channappaji.a" >&2
					echo "failed to create secret key. Check the private key of receiver" >&2
					rm file.enc file.enc.sign receiver1.priv_symm.enc receiver2.priv_symm.enc receiver3.priv_symm.enc
					exit 1
				fi
			#if the signature verification fails, it exits out of loop throwing error
			else
				echo "ERROR channappaji.a" >&2
				echo "Signature verification failed. Check the public key of sender" >&2
				rm file.enc file.enc.sign receiver1.priv_symm.enc receiver2.priv_symm.enc receiver3.priv_symm.enc 
				exit 1
			fi
		#Throws an error if a wrong zip file is provided and if file unzipping is not successful 
		else
			echo "ERROR channappaji.a" >&2
			echo "Failed to unzip the file. Provide the correct zip file" >&2
			exit 1
		fi
	fi
#Throws an error if anything else is passed as first argument
else
	echo "ERROR channappaji.a" >&2
	echo "Invalid Operation. Choose -sender or -receiver" >&2
fi
