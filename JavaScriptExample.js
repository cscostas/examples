/******************************************************************************/
/**
* File ecdCleanFields.js - JavaScript cleaning routines for CPG formlet fields.
* @author	Catherine Costas
*/
/******************************************************************************/

/*******************************************************************************
* Generic string validation routines
*******************************************************************************/

/**
* Function fldIsBlank - Checks if a string is blank or undefined
* @param {String} inString string to check
* @return true if string is blank or undefined, false otherwise
* @type Boolean
*/

function fldIsBlank( inString )
{
	if (inString == undefined)
		return true;

	if (inString.length == 0)
		return true;

	return false;
}

/**
* Function fldValidateList - Validates a provided string against a list of valid values.
* @param {String} inString string to validate
* @param {String} inValidValues comma-delimited list of valid values for comparison
* @return true if string is valid, false otherwise
* @type Boolean
*/

function fldValidateList( inString, inValidValues )
{
	if (fldIsBlank(inValidValues))
		return false;

	var workValidValues	= new Array(inValidValues.split(','));

	for (var i = 0; i < numArrayValid; i++)
	{
		if (inString == workArrayValid[i])
			return true;
	}
	return false;
}

/**
* Function fldValidateRegExp - Validates a provided string against a provided regular expression
* @param {String} inString string to validate
* @param {String} inRegExpValid regular expression to match against
* @return true if string matches the regexp, false otherwise
* @type Boolean
*/

function fldValidateRegExp( inString, inRegExpValid )
{
	if (fldIsBlank(inRegExpValid))
		return false;
		
	var testRegExpValid	= new RegExp(inRegExpValid);

	return testRegExpValid.test(inString);
}

/*******************************************************************************
* Boolean translation and test routines
*******************************************************************************/

/**
* Function fldGetBoolean - Takes a character code, and returns the corresponding Boolean value.
* @param {String} inChar character to check
* @return true if character is equivalent to true, false if character is equivalent to false, null if neither condition applies
* @type Boolean
*/

function fldGetBoolean( inChar )
{
	var regTrue			= '^[YyTt1]';
	var regFalse		= '^[NnFf0]';

	if (fldIsBlank(inChar))
		return false;
	
	if (fldValidateRegExp(inChar,regTrue))
		return true;

	if (fldValidateRegExp(inChar,regFalse))
		return false;

	return null;
}

/**
* Function fldIsTrue - Checks if a string is equivalent to true.  Only checks the first character of the string.
* @param {String} inString string to check
* @return true if first character is equivalent to true, false otherwise
* @type Boolean
*/

function fldIsTrue( inString )
{
	if (fldIsBlank(inString))
		return false;
	
	if (fldGetBoolean(inChar.charAt(0)) == true)
		return true;

	return false;
}

/**
* Function fldIsFalse - Checks if a string is equivalent to false.  Only checks the first character of the string.
* @param {String} inString string to check
* @return true if first character is equivalent to false, false otherwise
* @type Boolean
*/

function fldIsFalse( inString )
{
	if (fldIsBlank(inString))
		return false;
	
	if (fldGetBoolean(inChar.charAt(0)) == false)
		return true;

	return false;
}

/*******************************************************************************
* Generic cleaning routines
*******************************************************************************/

/**
* Function fldCleanString - Generic cleaning for string values.  Does the following:
*							- removes control characters 
*							- converts newline characters to single \n (\x0A)
*							- replaces whitespace (except newline characters) with single space
*							- compresses multiple spaces to single space
*							- removes spaces from beginning and end of field
*							- removes spaces before newlines
*							- truncates string to appropriate length (if provided).
* @param {String} inString string to clean
* @param {String} inStringLen length of string (default 0 - unlimited)
* @param {String} removeNonASCII remove non-ASCII characters (Y/N, default N)
* @return cleaned string or empty string on error
* @type String
*/

function fldCleanString( inString, inStringLen = 0, removeNonASCII = "N" )
{
	var regControl		= new RegExp('[\u0001-\u0008\u000B\u000C\u000E-\u001F\u007F-\u009F\u00AD]','g');
	var regNewlines		= new RegExp('[\u000A\u000D]','g');
	var regWhitespace	= new RegExp('[\u0009\u0020\u00A0]','g');
	var regNonASCII		= new RegExp('[\u0020-\u007E]','g');

	if (fldIsBlank(inString))
		return false;
	
	// copy the string to a holding buffer
	var workString		= new String(inString);

	// remove control characters
	workString			= workString.replace(regControl,'');

	// if removing non-ASCII characters, remove them here
	if (fldIsTrue(removeNonASCII))
		workString		= workString.replace(regNonASCII,'');

	// replace newline characters with single \n
	workString			= workString.replace(regNewlines,"\n");

	// replace remaining whitespace characters with space
	workString			= workString.replace(regWhitespace," ");

	// compress multiple whitespaces into single space
	workString			= workString.replace(/\s+/g," ");

	// remove spaces at beginning and end of field
	workString			= workString.replace(/^\s*/,'');
	workString			= workString.replace(/\s*$/,'');
	
	// remove spaces before newlines
	workString			= workString.replace(/\s*\n/g,"\n");

	// if length isn't 0, truncate string to given length
	if (! fldIsBlank(inStringLen) && inStringLen > 0)
		workString		= workString.substring(0,inStringLen);

	return workString;
}

/**
* Function fldCleanInteger - Generic cleaning for integer strings.  Removes all non-digits, then returns the corresponding numeric string.
* @param {String} inString string to clean
* @param {String} inStringLen length of integer string (default 0 - unlimited)
* @return cleaned integer string or empty string on error
* @type String
*/

function fldCleanInteger( inString, inStringLen = 0 )
{
	if (fldIsBlank(inString))
		return "";

	// remove all characters but digits
	var workString		= inString.replace(/[^\d]/g,'');

	// if length isn't 0, truncate string to given length
	if (! fldIsBlank(inStringLen) && inStringLen > 0)
		workString		= workString.substring(0,inStringLen);

	return workString;
}

/**
* Function fldCleanIDNumber - Generic cleaning for ID number strings.  Removes all characters but digits and dashes.
* @param {String} inString string to clean
* @return cleaned ID number string or empty string on error
* @type String
*/

function fldCleanIDNumber( inString )
{
	if (fldIsBlank(inString))
		return "";

	// remove all characters but digits and dashes
	var workString		= inString.replace(/[^\d-]/g,'');

	return workString;
}

/**
* Function fldCleanDate - Generic cleaning for date strings.  Supported formats:  
*							M[M]/D[D]/YYYY, M[M]-D[D]-YYYY, M[M].D[D].YYYY, M[M] D[D] YYYY
*							YYYY/M[M]/D[D], YYYY-M[M]-D[D], YYYY.M[M].D[D], YYYY M[M] D[D] YYYYMMDD
* 							Replaces all punctuation with spaces.  Breaks date into sections, then checks for
*							valid date portion values.  Reassembles and returns date in YYYY-MM-DD format.
* @param {String} inString string to clean
* @return cleaned date string or empty string on error
* @type String
*/

function fldCleanDate( inString )
{
	if (fldIsBlank(inString))
		return "";

	// copy the string to a holding buffer
	var workString		= new String(inString);

	// remove everything but digits, dashes, dots, slashes, and spaces
	workString			= workString.replace(/[^\d\/\. -]/g,'');

	// replace slashes, dashes, and dots with spaces
	workString			= workString.replace(/[\/\.-]/g," ");

	// compress multiple whitespaces into single space
	workString			= workString.replace(/\s+/g," ");

	var workDateParts	= new Array();

	// if there are no spaces in the string, read the date as YYYYMMDD
	if (workString.search(/\s/) >= 0)
	{
		workDateParts[0]	= slice(workString,0,4);
		workDateParts[1]	= slice(workString,4,6);
		workDateParts[2]	= slice(workString,6,8);
	}
	else
	{
		// split string into portions at space
		var workDateParts	= workString.split(' ');
	}

	var workYear		= 0;
	var workMonth		= 0;
	var workDay			= 0;

	// check to see which value is the year (either first or third)
	if (workDateParts[0].length == 4)
	{
		workYear		= parseInt(workDateParts[0]);
		workMonth		= parseInt(workDateParts[1]);
		workDay			= parseInt(workDateParts[2]);
	}
	else if (workDateParts[2].length == 4)
	{
		workMonth		= parseInt(workDateParts[0]);
		workDay			= parseInt(workDateParts[1]);
		workYear		= parseInt(workDateParts[2]);
	}
	else
		return "";

	if (workYear < 1900)
		return "";
	if (workMonth > 12)
		return "";

	// if either the month or day is 0, set to 1
	if (workMonth <= 0)
		workMonth == 1;
	if (workDay) <= 0)
		workDay == 1;

	// check the day value against the month (and year, if appropriate)
	switch(workMonth)
	{
		case 1:
		case 3:
		case 5:
		case 7:
		case 8:
		case 10:
		case 12:
			if (workDay > 31)
				return "";
			break;

		case 4:
		case 6:
		case 9:
		case 11:
			if (workDay > 30)
				return "";
			break;

		case 2:
			var maxDay = 28;

			// check for leap year
			if (workYear % 4 == 0)
			{
				if (workYear % 100 != 0)
					maxDay = 29;
				else if (workYear % 400 == 0)
					maxDay = 29;
			}
			if (workDay > maxDay)
				return "";
			break;

		default:
			return "";
			break;
	}

	// reassemble the string in YYYY-MM-DD format and return
	return workYear + "-" + (workMonth < 10 ? "0" : "") + workMonth + "-" + (workDay < 10 ? "0" : "") + workDay;
}

/**
* Function fldCleanEnum - Generic cleaning for an enumerated string (matching a list of specific values).  Cleans the string, then 
*   compares it against the provided list of valid values.
* @param {String} inString string to clean
* @param {String} inValidValues comma-delimited list of valid values for comparison
* @param {String} inStringLen length of integer string (default 0 - unlimited)
* @return cleaned string or empty string on error
* @type String
*/

function fldCleanEnum( inString, inValidValues, inStringLen = 0 )
{
	if (fldIsBlank(inString))
		return "";

	// remove all characters but digits
	var workString		= fldCleanString( inString, inStringLen, "Y" );
	if (fldIsBlank(workString))
		return "";
	
	if (fldValidateList( workString, inValidValues ))
		return workString;

	return "";
}

/**
* Function fldCleanYesNo - Checks if a string contains either "Yes" or "No".
* @param {String} inString string to check
* @return cleaned string or empty string on error
* @type String
*/

function fldCleanYesNo( inString )
{
	var workString		= fldCleanString(inString,1,"Y");
	if (fldIsBlank(workString))
		return "";

	switch(fldGetBoolean(workString))
	{
		case true:	return "Yes";
					break;
		case false:	return "No";
					break;
		default:	return "";
					break;
	}

	return "";
}

/*******************************************************************************
* OSSCR ID cleaning and verification routine
*******************************************************************************/

/**
* Function fldCleanOID - Cleans and verifies an OSSCR ID value.  Must be an integer with the last three digits matching an OSSCR type code.
* @param {String} inString string to clean/verify
* @param {String} inOIDTypes comma-delimited list of specific OID types to match (default all)
* @return cleaned string or empty string on error
* @type String
*/

function fldCleanOID( inString, inOIDTypes = "" )
{
	var validOIDTypes	= "01,02,03,04,05,06,07,08,09,10,11,12";
	var testOIDTypes 	= new Array();

	if (! fldIsBlank(inOIDTypes))
	{
		for (testType in inOIDTypes.split(','))
		{
			if (fldValidateList(testType, validOIDTypes))
			{
				testOIDTypes.push(testType);
			}
		}
	}

	// If we have input type(s), use those for the check.  Otherwise, use the full list.
	var validOIDList	= (testOIDTypes.length > 0 ? testOIDTypes.join(',') : validOIDTypes);

	// clean the input field as an integer
	var workOID			= fldCleanInteger(inString);
	if (workOID.length < 4)
		return "";

	// take the type off the end of the value
	var workOIDType		= workOID.slice(-3);

	// validate the type against the valid list
	if (fldValidateList(workOIDType, validOIDList))
		return workOID;
	
	return "";
}

/*******************************************************************************
* CRDB ID cleaning and verification routine
*******************************************************************************/

/**
* Function fldCleanCRDBID - Cleans a CRDB ID value.
* @param {String} inString string to clean/verify
* @return cleaned string or empty string on error
* @type String
*/

function fldCleanCRDBID( inString )
{
	return fldCleanInteger(inString);
}

/*******************************************************************************
* client number cleaning routine
*******************************************************************************/

/**
* Function fldCleanClientNumber - Cleans an organization or person client number.
* @param {String} inString string to clean/verify
* @return cleaned string or empty string on error
* @type String
*/

function fldCleanClientNumber( inString )
{
	var workString		= fldCleanIDNumber(inString);
	if (fldIsBlank(workString))
		return "";

	if (fldValidateRegExp(workString, '\d{3}-\d{3}-\d{2}'))
		return workString;

	return "";
}

