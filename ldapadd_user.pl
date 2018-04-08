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

# Variables for LDAP add commands.
my $ldapPassword;
my $admin = "cn=admin,dc=cst202,dc=edu";

if(@ARGV > 0 && @ARGV <= 4)
{
    # Check which argument the file is passed in as.

    # If there's only one arg, then look for the file there.
    if(@ARGV == 1)
    {
        $fileArg = $ARGV[0];
    }

    # Else if there's 2 args and one of them is the password switch,
    # check that the other arg is the file.
    elsif(@ARGV == 2 && $ARGV[0] eq "-p" && $ARGV[0] eq "-d")
    {
         $passwordSwitch = $ARGV[0];
         $fileArg = $ARGV[1];
         $ldapPassword = "secret";
    }

    # Else, if there's 2 arguments and no password switch is used, the first must be the -d switch
    # and the second must have the file.
    elsif(@ARGV == 2 && $ARGV[0] ne "-p" && $ARGV[0] eq "-d")
    {
        $dryRunSwitch = $ARGV[0];
        $fileArg = $ARGV[1];
    }
    
    # Else, if there's 3 args (The -p switch, the actual password, and the file),
    # then the third arg must have the file.
    elsif(@ARGV == 3 && $ARGV[1] eq "-p" && $ARGV[1] ne "-d")
    {
        $passwordSwitch = $ARGV[0];
        $passwordArg = $ARGV[1];
        $fileArg = $ARGV[2];
        $ldapPassword = $passwordArg;
    }
    
    # Else, if  there's 3 args (-p, -d, and the file),
    # ten same as above, but with the default password.
    elsif(@ARGV == 3 && $ARGV[1] eq "-p" && $ARGV[1] eq "-d")
    {
        $passwordSwitch = $ARGV[0];
        $dryRunSwitch = $ARGV[1];
        $fileArg = $ARGV[2];
        $ldapPassword = "secret";
    }

    # Else, if all args are used, the file is the last arg.
    elsif(@ARGV == 4 && $ARGV[3] ne "-p" && $ARGV[3] ne "-d")
    {   
        $passwordSwitch = $ARGV[0];
        $passwordArg = $ARGV[1];
        $dryRunSwitch = $ARGV[2];
        $fileArg = $ARGV[3];
        $ldapPassword = $passwordArg;
    }
    else
    {
        die "Invalid arguments entered. 
        Please only use the -p switch (with an otional password arg), and/or the -d switch, in that order.
        File must be the last argument."
    }

    if(defined $fileArg)
    {
        if($dryRunSwitch eq "-d")
        {
            print "Dry-run, displaying ldif files:\n";
            my @ldifs = MakeLdifFile($fileArg);
            foreach(@ldifs)
            {
                print;
                print "\n";
            }

            print "\n";
            print "\n";
            print "Dry-run, displaying ldapadd commands instead of running them:\n";
            foreach(@ldifs)
            {
                print "ldapadd -x,-D $admin -w $ldapPassword -f @ldifs\n";
            }

        }
        else
        {
            my @ldifs = MakeLdifFile($fileArg);
            foreach(@ldifs)
            {
                my $isForked;

                if(!($isForked = fork))
                {
                    exec ("ldapadd -x,-D $admin -w $ldapPassword -f @ldifs");
                }
            }
        }
        
    }
    else
    {
        die "Please specify a file to read users from.";
    }
}
else
{
    die "Invalid number of arguments entered.";
}

# Opens a file, reads its contents, then closes it.
# Then, makes an ldif file using the contents.
# Takes in a file variable as an argument.
sub MakeLdifFile
{
    my $counter = 0;
    my @ldifFileAray;

    # Open a file handle that contains the user-specified file.
    open(my $USERS_FILE, '<', @_) || die "Couldn't open file '@_'. Error returned was: $!";

    # While the user file handle is open
    while(<$USERS_FILE>)
    {
        $counter++;
        my $ldifFile;

        # Generate a random password and store it for use.
        my $randPass = CreateRandPass();

        # Make a salt
        my $salt = CreateRandPass();
        
        # Chomp off unwanted characters and split the contents of the user file
        chomp;
        ($userID, $groupID, $userName, $cName, $shell, $email) = split(',');
        $userPassword = `openssl passwd -1 salt "$salt" "$randPass"`;

        # Assign theuser a givenName and sName based on their first and last names.
        ($givenName, $sName) = split("", $cName);

        # Name the ldif file after the associated user.        
        $ldifFile = "$userName.ldif";

        # Open a new filehandle for the temp ldif file.
        open(my $LDIF_FILE, '>', $ldifFile);

        # Print out an ldif-formatted string to a file.
        print $LDIF_FILE "dn: uid=$userName,ou=People,dc=cst202,dc=edu
            uid: $userName
            cn: $cName
            givenName: $givenName
            sn: $sName
            mail: $email
            objectClass: person
            objectClass: organizationalPerson
            objectClass: inetOrgPerson
            objectClass: posixAccount
            objectClass: top
            objectClass: shadowAccount
            userPassword: {crypt}$userPassword
            loginShell: $shell
            uidNumber: $userID
            gidNumber: $groupID
            homeDirectory: /ldapusers/$userName";

            push(@ldifFileAray, $ldifFile);

            close($LDIF_FILE);

        last if($counter > $USERS_FILE);

    }

    close($USERS_FILE);
    
    return @ldifFileAray;
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

