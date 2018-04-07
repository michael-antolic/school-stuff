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

my $fileArg;


if(@ARGV > 0 && @ARGV <= 3)
{
    # Check which argument the file is passed in as.

    # If there's only one arg
    if(@ARGV == 1)
    {
        $fileArg = $ARGV[0];
    }
    elsif (@ARGV == 3)
    {
        $fileArg = $ARGV[2];
    }
    elsif (@ARGV == 3)
    {   
        $fileArg = $ARGV[3];
    }

    #do stuff here
    open(my $USERS_FILE, '<', $fileArg) || die "Couldn't open file '$fileArg'. Error returned was $!";
}
else
{
    die "Invalid number of arguments.";
}

