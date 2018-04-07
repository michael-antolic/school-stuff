#!/usr/bin/perl
#
# COOS 291 - Assignment 3
# Author: CST202 Michael Antolic
# Due: Wednesday, April 11th, 2018
#
# Purpose: Perl script to automatically add users from a file to an LDAP server.

use strict;
use warnings;
use Pod::Usage;

# Variables to hold command line arguments.
my $fileArg;
my $passwordSwitch;
my $passwordArg;
my $dryRunSwitch;

# Variables to hold each value in the passed-in file.
my $userID;
my $groupID;
my $userName;
my $cName;
my $shell;
my $email;
my $userPassword;
my $givenName;
my $sName;

if(@ARGV > 0 && @ARGV <= 3)
{
    # Check which argument the file is passed in as.

    # If there's only one arg, then look for the file there
    if(@ARGV == 1)
    {
        $fileArg = $ARGV[0];
    }
    
    # Else, if there's 3 args (The -p switch, the actual password, and the file)
    # then the third arg must have the file.
    elsif (@ARGV == 3)
    {
        $passwordSwitch = $ARGV[0];
        $passwordArg = $ARGV[1];
        $fileArg = $ARGV[2];
    }

    # Else, if all args are used, the file is the last arg.
    elsif (@ARGV == 3)
    {   
        $passwordSwitch = $ARGV[0];
        $passwordArg = $ARGV[1];
        $dryRunSwitch = $ARGV[2];
        $fileArg = $ARGV[3];
    }

    if($fileArg != undef)
    {
        print MakeLdifFile($fileArg);
    }
    else
    {
        die "No file specified.";
    }
}
else
{
    die "Invalid number of arguments.";
}

# Opens a file, reads its contents, then closes it.
# Then, makes an ldif file using the contents.
# Takes in a file variable as an argument.
sub MakeLdifFile
{
    my $ldifFile = 'temp.ldif';

    # Open a file handle.
    open(my $USERS_FILE, '<', @_) || die "Couldn't open file '@_'. Error returned was $!";

    # While the file handle is open
    while(<$USERS_FILE>)
    {
        open(my $LDIF_FILE, '>', $ldifFile);

        # Generate a random password and store it for use.
        my $randPass = CreateRandPass;

        # Make a salt
        my $salt = CreateRandPass;
        
        chomp;
        ($userID, $groupID, $userName, $cName, $shell, $email) = split(',');
        $userPassword = `openssl passwd -1 salt "$salt" "$randPass"`;

        ($givenName, $sName) = split("", $cName);

        print $LDIF_FILE "dn: uid=$userName,ou=People,dc=cst202,dc=edu\n
            uid: $userName\n
            cn: $cName\n
            givenName: $givenName\n
            sn: $sName\n
            mail: $email\n
            objectClass: person\n
            objectClass: organizationalPerson\n
            objectClass: inetOrgPerson\n
            objectClass: posixAccount\n
            objectClass: top\n
            objectClass: shadowAccount\n
            userPassword: {crypt}$userPassword\n
            loginShell: $shell\n
            uidNumber: $userID\n
            gidNumber: $groupID\n
            homeDirectory: /ldapusers/$userName\n";
    }

    close($USERS_FILE);
    close($LDIF_FILE);

    return $ldifFile;
}

# Takes no arguments and returns a random 8-14  character password
sub CreateRandPass {
	my @valid_chars = ("A".."Z", "a".."z",0..9,"!","?","@","#","%","^","&","*");
	my $password;

	for (1..(int(rand(7) + 8)))
	{
		$password .= $valid_chars[rand @valid_chars];
	}

	return $password;
}

