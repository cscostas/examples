require $ProjDir + "active/lib_local/ruby/osscr_ruby_environment.rb"

module CompensationCalc

##
##  get_rel_parent_id
##    parameters:   inRelID       CRDB ID for relationship record
##                  inRelOID      input OSSCR ID for relationship record
##    returns:      OSSCR ID of relationship record with correct relationship code
##  Given a CRDB relationship ID, returns the OSSCR ID which corresponds to the 
##    relationship with a type/code of EMPLOYMENT/EMPLOYEE_OF.
##

  def self.get_rel_parent_id inRelID, inRelOID
	inRelID.untaint
	inRelOID.untaint

    outRelOID       = inRelOID

    srchRelID       = inRelID.to_s.strip

	# if the search CRDB ID is null, get the CRDB ID from OSSCR, based on the input OID
    if (srchRelID !~ /^\d+$/)
      sql_statement = "SELECT PARTY_ID FROM HZ_RELATIONSHIPS WHERE O_PARTY_ID = ?"
      srchRelID     = ExecutePreparedStmt(:MySQL, sql_statement, inRelOID.to_s.strip).fetch_array.first
    end
	  
    srchRelID.untaint
    
    sql_statement   = "SELECT O_PARTY_ID FROM HZ_RELATIONSHIPS WHERE PARTY_ID = ? AND RELATIONSHIP_TYPE = 'EMPLOYMENT' AND RELATIONSHIP_CODE = 'EMPLOYEE_OF'"

    outRelOID       = ExecutePreparedStmt(:MySQL, sql_statement, srchRelID).fetch_array.first
    dplog("COMPENSATION","parent rel OID = #{outRelOID}")

    outRelOID.nil?  ? inRelOID : outRelOID
  rescue => e
    # return inRelOID on error
    inRelOID
  end

##
##  person_is_clergy?
##    parameters:   inRelOID      OSSCR ID for relationship record or compensation record
##    returns:      true/false: is this person clergy?
##  Given a compensation record ID or relationship ID, determines whether or not the
##  associated person is clergy.
##

  def self.person_is_clergy?(inRelOID)
    clergyID        =  nil

    srchRelOID      =  inRelOID.to_s.strip
    return false if (srchRelOID !~ /^\d+$/) || ((! srchRelOID.end_with?("05")) && (! srchRelOID.end_with?("13")))
    srchRelOID.untaint

    sql_statement   =  "SELECT ATTRIBUTE2 FROM HZ_PERSON_PROFILES WHERE O_PARTY_ID = "
    sql_statement   += "(SELECT O_SUBJECT_ID FROM HZ_RELATIONSHIPS WHERE O_PARTY_ID = "
    if (srchRelOID.end_with?("05"))
      sql_statement += "? );"
    else
      sql_statement += "(SELECT O_REL_PARTY_ID FROM CPG_HZ_COMPENSATION WHERE O_COMPENSATION_ID = ?));"
    end

    clergyID        =  ExecutePreparedStmt(:MySQL, sql_statement, srchRelOID).fetch_array.first
    dplog("COMPENSATION","clergyID = #{clergyID}")

    return (! clergyID.nil?)
  rescue => e
    # return false on error
    false
  end

##
##  decimal_to_integer
##    parameters:   inDecimal        a decimal value (as a string)
##    returns:      converted value as integer
##  Converts an input string of digits into a decimal value (2 digits after the point), then
##  removes the decimal point and multiplies the value by 100 in preparation for integer math.
##

  def self.decimal_to_integer(inDecimal)
    workString    = String.to_decimal(inDecimal.to_s).gsub(/\./,'')
    return 0 if workString == ""
  
    workString.to_i * 100
  rescue => e
    # return 0 on error
    0
  end
  
##
##  integer_to_decimal
##    parameters:   inInteger        an integer value
##    returns:      converted value as a decimal string
##  Converts an integer (the output from integer math) to a decimal string.  The value is divided by
##	100.0 to enforce rounding.  The last 2 digits of the rounded value are placed after the decimal point.
##

  def self.integer_to_decimal(inInteger)
    (inInteger / 100.0).round.to_s.sub(/^(-?\d*)(\d\d)$/,'\1.\2')
  rescue => e
    # return blank string on error
    ""
  end

##
##  calculate
##    parameters:   params        a hash containing a compensation record
##    returns:      params with added calculated fields
##  Main calculation routine.  Takes an input compensation record, and uses the contained data to
##  generate and add the calculated fields.
##

  def self.calculate(params)
    # set the working values
    isClergy                                   = nil
    isClergyFlag                               = nil
  
    workCashStipend                            = 0
    workUtilities                              = 0
    workDepTuitionPaid                         = 0
    workSSTaxReimbursement                     = 0
    workOtherTaxableIncome                     = 0
    workReceivesChurchHousing                  = "N"
    workReceivesMeals                          = "N"
    workHousingEquity                          = 0
    workERPaid403B                             = 0
    workHousingCashCompReceived                = 0
  
    workCalcHousingAmount                      = ""
    workScheduledTAC                           = ""
    workRSVPTAC                                = ""

    dplog("COMPENSATION","input parameters: #{params.inspect}")

    params.each{ |k,v|
      case k.to_s.upcase
        when "O_COMPENSATION_ID"
          isClergy                             = person_is_clergy?(v.to_s)
        when "O_REL_PARTY_ID"
          isClergy                             = person_is_clergy?(v.to_s)
        when "CASH_STIPEND"
          workCashStipend                      = decimal_to_integer(v.to_s)
        when "UTILITIES"
          workUtilities                        = decimal_to_integer(v.to_s)
        when "DEP_TUITION_PAID"
          workDepTuitionPaid                   = decimal_to_integer(v.to_s)
        when "SS_TAX_REIMBURSEMENT"
          workSSTaxReimbursement               = decimal_to_integer(v.to_s)
        when "OTHER_TAXABLE_INCOME"
          workOtherTaxableIncome               = decimal_to_integer(v.to_s)
        when "RECEIVES_CHURCH_HOUSING"
          workReceivesChurchHousing            = v.to_s.upcase
        when "RECEIVES_MEALS"
          workReceivesMeals                    = v.to_s.upcase
        when "HOUSING_EQUITY"
          workHousingEquity                    = decimal_to_integer(v.to_s)
        when "ER_PAID_403B"
          workERPaid403B                       = decimal_to_integer(v.to_s)
        when "HOUSING_CASH_COMP_RECEIVED"
          workHousingCashCompReceived          = decimal_to_integer(v.to_s)
        when "IS_CLERGY"
          isClergyFlag                         = v.to_s.upcase

      end
    }

	# store the input calculated values (if any) in backup fields
	params["INPUT_CALC_HOUSING_AMOUNT"]        = (params.has_key?("INPUT_CALC_HOUSING_AMOUNT") ? params["INPUT_CALC_HOUSING_AMOUNT"] :
	                                                (params.has_key?("CALC_HOUSING_AMOUNT")    ? params["CALC_HOUSING_AMOUNT"]       : nil))
	params["INPUT_SCHEDULED_TAC"]              = (params.has_key?("INPUT_SCHEDULED_TAC")       ? params["INPUT_SCHEDULED_TAC"]       :
	                                                (params.has_key?("SCHEDULED_TAC")          ? params["SCHEDULED_TAC"]             : nil))
	params["INPUT_RSVP_TAC"]                   = (params.has_key?("INPUT_RSVP_TAC")            ? params["INPUT_RSVP_TAC"]            :
	                                                (params.has_key?("RSVP_TAC")               ? params["RSVP_TAC"]                  : nil))
  
    dplog("COMPENSATION","Input CALC_HOUSING_AMOUNT = " + (params["INPUT_CALC_HOUSING_AMOUNT"].nil? ? "nil" : params["INPUT_CALC_HOUSING_AMOUNT"]))
    dplog("COMPENSATION","Input SCHEDULED_TAC = " + (params["INPUT_SCHEDULED_TAC"].nil? ? "nil" : params["INPUT_SCHEDULED_TAC"]))
    dplog("COMPENSATION","Input RSVP_TAC = " + (params["INPUT_RSVP_TAC"].nil? ? "nil" : params["INPUT_RSVP_TAC"]))

    # if the IS_CLERGY parameter was used, use it to override the calculated isClergy value from O_COMPENSATION_ID/O_REL_PARTY_ID
    dplog("COMPENSATION","isClergyFlag: " + (isClergyFlag.nil? ? "nil" : isClergyFlag))

    isClergy = (isClergyFlag.start_with?("Y") ? true : false) if ((! isClergyFlag.nil?) && (! isClergyFlag.empty?))

    dplog("COMPENSATION","isClergy: " + (isClergy.nil? ? "nil" : (isClergy ? "Y" : "N")))

    #  Calculation formulas:
    #    CALC_HOUSING_AMOUNT                   =  (CASH_STIPEND + UTILITIES + 
    #                                                 (isClergy ? (DEP_TUITION_PAID + SS_TAX_REIMBURSEMENT) : 0)) * 
    #                                               (RECEIVES_CHURCH_HOUSING ? (RECEIVES_MEALS ? 40% : 30%) : 0)
    #    SCHEDULED_TAC                         =  (CASH_STIPEND + UTILITIES + 
    #                                               (isClergy ? 
    #                                                  (SS_TAX_REIMBURSEMENT + DEP_TUITION_PAID + ER_PAID_403B + HOUSING_EQUITY + OTHER_TAXABLE_INCOME +
    #                                                   (RECEIVES_CHURCH_HOUSING ? 
    #                                                      (RECEIVES_MEALS ? 
    #                                                        CALC_HOUSING_AMOUNT :
    #                                                        (HOUSING_CASH_COMP_RECEIVED > CALC_HOUSING_AMOUNT ? HOUSING_CASH_COMP_RECEIVED : CALC_HOUSING_AMOUNT)
    #                                                      ) : HOUSING_CASH_COMP_RECEIVED
    #                                                    )
    #                                                  ) : CALC_HOUSING_AMOUNT
    #                                                )
    #                                              )
    #    RSVP_TAC                              =  SCHEDULED_TAC - (isClergy ? (ER_PAID_403B + HOUSING_EQUITY) : 0)
  
    workCalcHousingAmount                      =  workCashStipend + workUtilities
    workCalcHousingAmount                      += workDepTuitionPaid + workSSTaxReimbursement if isClergy
    if workReceivesChurchHousing == "Y"
      if workReceivesMeals == "Y"
        workCalcHousingAmount                  *= 4
      else
        workCalcHousingAmount                  *= 3
      end
      workCalcHousingAmount                    /= 10
    else
      workCalcHousingAmount                    *= 0
    end
  
    workScheduledTAC                           =  workCashStipend + workUtilities
    if isClergy
      workScheduledTAC                         += (workSSTaxReimbursement + workDepTuitionPaid + workERPaid403B + workHousingEquity + workOtherTaxableIncome) 
      if workReceivesChurchHousing == "Y"
        if workReceivesMeals == "Y"
          workScheduledTAC                     += workCalcHousingAmount
        else
          workScheduledTAC                     += (workHousingCashCompReceived > workCalcHousingAmount ? workHousingCashCompReceived : workCalcHousingAmount)
        end
      else
        workScheduledTAC                       += workHousingCashCompReceived
      end
    else
      workScheduledTAC                         += workCalcHousingAmount
    end
  
    workRSVPTAC                                =  workScheduledTAC 
    workRSVPTAC                                -= (workERPaid403B + workHousingEquity) if isClergy
  
    # Add the calculated values to the parameters
    params["CALC_HOUSING_AMOUNT"]              = integer_to_decimal(workCalcHousingAmount)
    params["SCHEDULED_TAC"]                    = integer_to_decimal(workScheduledTAC)
    params["RSVP_TAC"]                         = integer_to_decimal(workRSVPTAC)
  
    params
  end
  
end
