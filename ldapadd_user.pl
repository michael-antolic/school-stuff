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


my $ldapFile=<STDIN>;

