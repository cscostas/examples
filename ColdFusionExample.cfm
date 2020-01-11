<cfscript>

/**
* File:                         utilsJSON
* Description:                  utility routines to convert ColdFusion data to/from JSON format.
*/

/**
* Function ConvertToJSON - Converts an object to JSON format.  If the value isn't a simple
*                               value, calls itself recursively to deal with the additional data.
* @param {any} inData data value to convert
* @return JSON formatted data string
* @type String
*/

function ConvertToJSON(inData)
{
    var outString               = "";
    var workString              = "";
    var workKeys                = 0;

    var i                       = 0;

    // Treat the data according to the data type.
    if (IsSimpleValue(inData))
    {
        // if the data contains a newline (\x0A), convert it to \n
        workString              = REReplace(inData,"\x0A","\n","ALL");

        // if the data contains a doublequote, put a \ before it
        workString              = REReplace(workString,'"','\"',"ALL");

        // For simple values, surround with quotes and return
        outString               = outString & '"' & workString & '"';
    }
    else if (IsArray(inData))
    {
        outString               = outString & '[';

        for (i = 1; i <= ArrayLen(inData); i++)
        {
            if (i > 1)
                outString       = outString & ',';

            // call conversion routine recursively for each array element
            outString           = outString & ConvertToJSON(inData[i]);
        }

        outString               = outString & ']';
    }
    else 
    {
        outString               = outString & '{';

        // for structures and objects, pull the keys to an array, then walk through the structure by key
        workKeys                = StructKeyArray(inData);

        for (i = 1; i <= ArrayLen(workKeys); i++)
        {
            if (i > 1)
                outString       = outString & ',';

            // output the key
            outString           = outString & '"' & workKeys[i] & '":';

            // call conversion routine recursively for the value in each key/value pair
            outString           = outString & ConvertToJSON(inData[workKeys[i]]);
        }

        outString               = outString & '}';
    }

    return outString;
}

/**
* Function ConvertFromJSON - Converts an object from JSON format to ColdFusion.  Wrapper for DeserializeJSON.
*                               Replaces incoming "null" values with blank strings.
* @param {String} inJSON JSON data value to convert
* @return ColdFusion equivalent data
* @type struct
*/

function ConvertFromJSON(inJSON)
{
    var workString              = "";

    // replace any "null" strings in the incoming JSON buffer with blank strings
    workString                  = REReplace(inJSON,":\s*null\b",':""',"ALL");

    // convert the JSON data to CF format, and return
    return DeserializeJSON(workString);
}

/**
* Function ppJSON - "Pretty-prints" a JSON string.  
* @param {String} inJSON JSON formatted data string
* @return reformatted JSON string
* @type String
*/

function ppJSON(inJSON)
{
    var outJSON                 = "";
    var workJSON                = "";
    var currLineLdr             = 0;
    var currLinePtr             = 1;
    var currChar                = "";

    var i                       = 0;

    // check the first character of the string
    while (currLinePtr <= Len(inJSON))
    {
        currChar                = Mid(inJSON,currLinePtr,1);

        switch(currChar)
        {
            case '{':
                if (currLineLdr neq "")
                {
                    outJSON         = outJSON & "<br />";
                    for (i = 1; i <= currLineLdr; i++)
                        outJSON     = outJSON & "&nbsp;&nbsp;&nbsp;&nbsp;"; 
                }

                outJSON             = outJSON & chr(123) & "<br />";
                currLineLdr++;

                currLinePtr++;
                break;

            case '}':
                outJSON             = outJSON & "<br />";
                currLineLdr--;
                if (currLineLdr > 0)
                {
                    for (i = 1; i <= currLineLdr; i++)
                        outJSON     = outJSON & "&nbsp;&nbsp;&nbsp;&nbsp;";
                }
                outJSON             = outJSON & chr(125);

                currLinePtr++;
                break;

            case ',':
                outJSON             = outJSON & ',' & "<br />";

                currLinePtr++;
                break;

            default:
                if (currLineLdr > 0)
                {
                    for (i = 1; i <= currLineLdr; i++)
                        outJSON     = outJSON & "&nbsp;&nbsp;&nbsp;&nbsp;";
                }
            
                for (; currLinePtr <= Len(inJSON); currLinePtr++)
                {
                    currChar        = Mid(inJSON,currLinePtr,1);
                    if (currChar eq chr(123) or currChar eq chr(125) or currChar eq ',')
                        break;
                    outJSON         = outJSON & currChar;
                }

                break;
        }
    }

    return outJSON;
}

/**
* Function SpacePrepend - Prepend every field in the incoming data with a leading space.  This is necessary for data 
*                               being passed into ColdFusion's SerializeJSON() function, since that routine 
*                               does weird things with non-string data.  This routine is called recursively.
* @param {any} inData ColdFusion data to space pad
* @return space-padded data
* @type any
*/

function SpacePrepend(inData)
{
    var workData                = 0;
    var inKeys                  = 0;
    var i                       = 0;

    // Treat the data according to the data type.

    if (IsSimpleValue(inData))
    {
        // For simple values, convert to string, surround with spaces and return
        return " " & ToString(inData);
    }
    else if (IsArray(inData))
    {
        // for arrays, walk through the array and convert each value in place
        workData                = [];

        for (i = 1; i <= ArrayLen(inData); i++)
        {
            workData[i]         = SpacePrepend(inData[i]);
        }

        return workData;
    }
    else 
    {
        // for structures and objects, pull the keys to an array, then walk through the structure by key
        workData                = StructNew();
        inKeys                  = StructKeyArray(inData);

        for (i = 1; i <= ArrayLen(inKeys); i++)
        {
            workData[inKeys[i]] = SpacePrepend(inData[inKeys[i]]);
        }

        return workData;
    }
}

/**
* Function SpaceClear - Clears leading and trailing spaces from JSON data fields.  This is necessary for data being 
*                               passed into ColdFusion's SerializeJSON() function, since that routine does weird things 
*                               with non-string data.  
* @param {String} inJSONString JSON-formatted data string
* @return JSON string with extraneous spaces removed
* @type String
*/

function SpaceClear(inJSONString)
{
    var workJSONString          = inJSONString;

    // remove spaces that occur immediately before or immediately after quotes
    workJSONString              = REReplace(workJSONString,' "','"',"ALL");
    workJSONString              = REReplace(workJSONString,'" ','"',"ALL");

    // return the cleaned string
    return workJSONString;
}

</cfscript>