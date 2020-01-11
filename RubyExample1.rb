$ProjDir ||= ((__FILE__[/(.*\/)active\b/, 1] || `pwd`[/(.*\/)active\b/, 1]).untaint or
               raise "Failed to identify project directory (looking for 'active' in path).");
require $ProjDir + "active/lib_local/ruby/osscr_ruby_environment.rb"

####################
## CompensationCalculation
##   Web service call to calculate field values for the CPG_HZ_COMPENSATION table
## inputs (CGI)
##   CompRecord   JSON block containing some or all of the following CPG_HZ_COMPENSATION record fields:
##     CASH_STIPEND
##     UTILITIES
##     DEP_TUITION_PAID
##     SS_TAX_REIMBURSEMENT
##     OTHER_TAXABLE_INCOME
##     HOUSING_EQUITY
##     ER_PAID_403B
##     HOUSING_CASH_COMP_RECEIVED
##     RECEIVES_CHURCH_HOUSING
##     RECEIVES_MEALS
##     O_REL_PARTY_ID
##     O_COMPENSATION_ID
##     IS_CLERGY                             "Y" or "N" value indicating whether or not this person is clergy
## outputs
##   JSON block containing calculated fields
####################

class CompensationCalculation

  def initialize()
    @workRecord                               = {}
    @outRecord                                = {}

    @workCompRecord                           = nil
    @workCompRecordInput                      = nil

    @workCashStipend                          = nil
    @workUtilities                            = nil
    @workDepTuitionPaid                       = nil
    @workSSTaxReimbursement                   = nil
    @workOtherTaxableIncome                   = nil
    @workHousingEquity                        = nil
    @workERPaid403B                           = nil
    @workHousingCashCompReceived              = nil
    @workReceivesChurchHousing                = nil
    @workReceivesMeals                        = nil
    @workIsClergy                             = nil
    @workORelPartyID                          = nil
  end

  def work(cgi, auth_creds)
    @cgi = cgi; 
    
    @workRecord    = {
      "CASH_STIPEND"                         => 0.0,
      "UTILITIES"                            => 0.0,
      "DEP_TUITION_PAID"                     => 0.0,
      "SS_TAX_REIMBURSEMENT"                 => 0.0,
      "OTHER_TAXABLE_INCOME"                 => 0.0,
      "HOUSING_EQUITY"                       => 0.0,
      "ER_PAID_403B"                         => 0.0,
      "HOUSING_CASH_COMP_RECEIVED"           => 0.0,
      "RECEIVES_CHURCH_HOUSING"              => "N",
      "RECEIVES_MEALS"                       => "N",
      "IS_CLERGY"                            => ""
    }

    @workCompRecord                           = nil
    @workCompRecordInput                      = nil
    @workCashStipend                          = nil
    @workUtilities                            = nil
    @workDepTuitionPaid                       = nil
    @workSSTaxReimbursement                   = nil
    @workOtherTaxableIncome                   = nil
    @workHousingEquity                        = nil
    @workERPaid403B                           = nil
    @workHousingCashCompReceived              = nil
    @workReceivesChurchHousing                = nil
    @workReceivesMeals                        = nil
    @workIsClergy                             = nil
    @workORelPartyID                          = nil
    @workOCompensationID                      = nil

    ## The user inputs information as a JSON block ("CompRecord") which is split into individual working variables.
    @workCompRecordInput                      = extract_param("CompRecord", /(.*)/mu, nil)
    methodProcessingError(-1,"CompRecord is empty") if String.NilOrEmpty?(@workCompRecordInput)

    ## if that parser does not bork, we will assume the JSON was formatted correctly
    begin
      @workCompRecord                         = JSON.parse(@workCompRecordInput)
    rescue
      methodProcessingError(0,"CompRecord is not in valid JSON format") 
    end

    methodProcessingError(row_index + 10000,"CompRecord is not a Hash") unless @workCompRecord.is_a?(Hash)
   
    ## pull the individual values into working variables
    @workCompRecord.each{ |k,v|
      case k.to_s.upcase
        when "CASH_STIPEND"
          @workCashStipend                    = v
        when "UTILITIES"
          @workUtilities                      = v
        when "DEP_TUITION_PAID"
          @workDepTuitionPaid                 = v
        when "SS_TAX_REIMBURSEMENT"
          @workSSTaxReimbursement             = v
        when "OTHER_TAXABLE_INCOME"
          @workOtherTaxableIncome             = v
        when "HOUSING_EQUITY"
          @workHousingEquity                  = v
        when "ER_PAID_403B"
          @workERPaid403B                     = v
        when "HOUSING_CASH_COMP_RECEIVED"
          @workHousingCashCompReceived        = v
        when "RECEIVES_CHURCH_HOUSING"
          @workReceivesChurchHousing          = v
        when "RECEIVES_MEALS"
          @workReceivesMeals                  = v
        when "IS_CLERGY"
          @workIsClergy                       = v
        when "O_REL_PARTY_ID"
          @workORelPartyID                    = v
        when "O_COMPENSATION_ID"
          @workOCompensationID                = v
      end
    }

    ## load the working values into our hash
    @workRecord["CASH_STIPEND"]               = @workCashStipend              unless @workCashStipend == nil              || @workCashStipend == ""
    @workRecord["UTILITIES"]                  = @workUtilities                unless @workUtilities == nil                || @workUtilities == ""
    @workRecord["DEP_TUITION_PAID"]           = @workDepTuitionPaid           unless @workDepTuitionPaid == nil           || @workDepTuitionPaid == ""
    @workRecord["SS_TAX_REIMBURSEMENT"]       = @workSSTaxReimbursement       unless @workSSTaxReimbursement == nil       || @workSSTaxReimbursement == ""
    @workRecord["OTHER_TAXABLE_INCOME"]       = @workOtherTaxableIncome       unless @workOtherTaxableIncome == nil       || @workOtherTaxableIncome == ""
    @workRecord["HOUSING_EQUITY"]             = @workHousingEquity            unless @workHousingEquity == nil            || @workHousingEquity == ""
    @workRecord["ER_PAID_403B"]               = @workERPaid403B               unless @workERPaid403B == nil               || @workERPaid403B == ""
    @workRecord["HOUSING_CASH_COMP_RECEIVED"] = @workHousingCashCompReceived  unless @workHousingCashCompReceived == nil  || @workHousingCashCompReceived == ""
    @workRecord["RECEIVES_CHURCH_HOUSING"]    = @workReceivesChurchHousing    unless @workReceivesChurchHousing == nil    || @workReceivesChurchHousing == ""
    @workRecord["RECEIVES_MEALS"]             = @workReceivesMeals            unless @workReceivesMeals == nil            || @workReceivesMeals == ""
    @workRecord["IS_CLERGY"]                  = @workIsClergy                 unless @workIsClergy == nil                 || @workIsClergy == ""
    @workRecord["O_REL_PARTY_ID"]             = @workORelPartyID              unless @workORelPartyID == nil              || @workORelPartyID == ""
    @workRecord["O_COMPENSATION_ID"]          = @workOCompensationID          unless @workOCompensationID == nil          || @workOCompensationID == ""

    ## Run the calculations.  This adds the calculated values to @workRecord
    CompensationCalc::calculate(@workRecord)

    ## Add the new calculated fields to the output block
    @outRecord["CALC_HOUSING_AMOUNT"]         = @workRecord["CALC_HOUSING_AMOUNT"]
    @outRecord["SCHEDULED_TAC"]               = @workRecord["SCHEDULED_TAC"]
    @outRecord["RSVP_TAC"]                    = @workRecord["RSVP_TAC"]

    JSON.dump(@outRecord)
  end

  def fieldList4TestPage
    {"CompRecord" => "textarea" }
  end

private

  def methodProcessingError(errorCode = nil, errorMessage = nil)
    outErrorCode = errorCode.nil? ? "" : ", ErrorCode: #{errorCode.to_s}" 

    earlyReturn("Invalid JSON Format for Method: CompensationCalculation, Param: CompRecord#{outErrorCode}") if errorMessage.nil?
    earlyReturn("ERROR processing CompensationCalculation: #{errorMessage}#{outErrorCode}")
  end
end
