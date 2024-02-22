# Cryptographic_functions
This project designs and implements a cryptographic system, so a group of users may securely share files providing Confidentiality, Integrity and Authentication services. I have used a combination of symmetric cryptography, asymmetric cryptography and hashing algorithms to achieve this. 

1.	An implementation of this Secure Group File sharing system enables a sender to encrypt and sign a file to be sent to an specified group of recipients (each of them will provide their public key to the sender). Any of the receivers can  verify the sender’s signature and then decrypt the encrypted file. 
2.	The bash script implements this cryptographic scheme. There are 4 group members (1 sender, 3 receivers), and all group members have their own ECC  private-public key pairs and have previously shared their public key with each other.  
3.	The sender's side script outputs just one zip file  and the receiver's side outputs the plaintext file only if the signature verification is correct. All the files created during intermediate steps of the sender/receiver process will be deleted. 

The arguments passed for the script are as follows:
1.	For encrypting and signing a file:
	./crypto.sh -sender receiver1.pub receiver2.pub receiver3.pub sender.priv <plaintext_file> <zip_file>

2.	For decrypting and verifying the signature of a file:
	./crypto.sh -receiver receirver<#>.priv sender.pub <zip_file> <plaintext_file>

The script also contains basic level of error handling with appropriate message prompts to the user printed to stderr

