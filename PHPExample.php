<?php

/*******************************************************************************
***
***  File:              index.php
***  Description:       Main menu for SFD Grades database site.
***  Author:            Catherine Costas
***  Copyright:			Copyright (c) 2010, Catherine Costas, ALL RIGHTS RESERVED
***
*******************************************************************************/

/**************************************
**	Standard include files
**************************************/

require_once "pagefx.php";
require_once "cleanfx.php";
require_once "dbfx.php";
require_once "sessionfx.php";

/******************
**	Start the session.  If the session isn't active, initialize the session variables
**	and redirect to the login page.
******************/

session_start();

if (! isset($_SESSION['has_authenticated']) || $_SESSION['has_authenticated'] == FALSE)
{
	# Initialize the session variables
	$_SESSION['projectname']	= 'SFD Grades Database';
	$_SESSION['projectroot']	= 'sfdgrades';
#	$_SESSION['webhostname']	= $_SERVER['HTTP_HOST'];
	$_SESSION['webhostname']	= 'localhost';
	$_SESSION['dbhostname']		= 'localhost';
	$_SESSION['dbname']			= 'sfdgrades';
	$_SESSION['projecthome']	= 'http://' . $_SESSION['webhostname'] . '/' . $_SESSION['projectroot'] . '/index.php';

	$_SESSION['pageheader']	= <<<PGHEADER

<table class="hdr">
<tr>
	<td class="hdr" width="12%"><img src="/sfdgrades/images/SFDLogo.jpg" alt="SFD Logo" height="96"></th>
	<th class="hdr">
		<h1>The School For Deacons Grades Database</h1>
	</th>
	<td class="hdr">
		<p class="hdr">
			2451 Ridge Road<br />
		   	Berkeley, CA  94709<br />
		   	<a href="http://www.sfd.edu">http://www.sfd.edu</a>
		</p>
	</td>
</tr>
</table>

<hr />
PGHEADER;

	# redirect to login page
	print_redirect("../../cgi-bin/login.php");
}

/******************
**	Menu
******************/

// Print the page header
print_pageheader("Main Menu");

// Print the page body
$pagebody = <<<PAGEINFO

<h3>Add/Update/Delete Records</h3>
<p class="menu">
	<a href="audStudents.php">Students</a><br />
	<a href="audCourses.php">Courses</a><br />
	<a href="audInstructors.php">Instructors</a>
</p>

<h3>Registration and Grades</h3>
<p class="menu">
	<a href="audSemesters.php">Courses Per Semester</a><br />
	<a href="Registration.php">Student Registration</a><br />
	<a href="Grades.php">Student Grades</a>
</p>

<h3>Reports</h3>
<p class="menu">
	<a href="Transcript.php">Student Transcript</a><br />
	<a href="ClassList.php">Class List</a>
</p>

<br />

PAGEINFO;

print $pagebody;

print_pagefooter();

?>

