<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" exclude-result-prefixes="xsl wd this xsd adp peci is"
	xmlns:wd="urn:com.workday/bsvc" 
	xmlns:adp="http://www.workday.com/integration/adp"
	xmlns:this="urn:this-stylesheet"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:peci="urn:com.workday/peci"
	xmlns:ptdf="urn:com.workday/peci/tdf"
	xmlns:is="java:com.workday.esb.intsys.xpath.ParsedIntegrationSystemFunctions">	
	
	<xsl:output encoding="UTF-8" indent="yes" method="xml" version="1.0"/>

	<xsl:param name="company.id"/>
	<xsl:param name="pay.group.id"/>
	<xsl:param name="ia.Split.Benefit.File"/>
	<xsl:param name="ia.Split.PaymentElection.File"/>
	<xsl:param name="is.IncludeBenefitInfo"/>
	<xsl:param name="is.IncludeDirectDepositInfo"/>	
	<xsl:param name="ia.EffecitveDatingEnabled"/>

	<xsl:variable name="ACTIVE"><xsl:text>A</xsl:text></xsl:variable>
	<xsl:variable name="TERMINATED"><xsl:text>T</xsl:text></xsl:variable>
	<!--<xsl:variable name="LOA"><xsl:text>L</xsl:text></xsl:variable>-->
	<xsl:variable name="DECEASED"><xsl:text>D</xsl:text></xsl:variable>
	<xsl:variable name="Australia_Nationality"><xsl:text>Australia</xsl:text></xsl:variable>
	<xsl:variable name="Belgium_Nationality"><xsl:text>Belgium</xsl:text></xsl:variable>
	<xsl:variable name="Brazil_Nationality"><xsl:text>Brazil</xsl:text></xsl:variable>
	<xsl:variable name="Estonia_Nationality"><xsl:text>Estonia</xsl:text></xsl:variable>
	<xsl:variable name="HongKong_Nationality"><xsl:text>Hong Kong</xsl:text></xsl:variable>
	<xsl:variable name="Hungary_Nationality"><xsl:text>Hungary</xsl:text></xsl:variable>
	<xsl:variable name="Indonesia_Nationality"><xsl:text>Indonesia</xsl:text></xsl:variable>
	<xsl:variable name="Japan_Nationality"><xsl:text>Japan</xsl:text></xsl:variable>
	<xsl:variable name="Malaysia_Nationality"><xsl:text>Malaysia</xsl:text></xsl:variable>
	<xsl:variable name="Netherlands_Nationality"><xsl:text>Netherlands</xsl:text></xsl:variable>
	<xsl:variable name="Singapore_Nationality"><xsl:text>Singapore</xsl:text></xsl:variable>
	<xsl:variable name="Thailand_Nationality"><xsl:text>Thailand</xsl:text></xsl:variable>
	<xsl:variable name="Ukraine_Nationality"><xsl:text>Ukraine</xsl:text></xsl:variable>
	<xsl:variable name="UAE_Nationality"><xsl:text>United Arab Emirate</xsl:text></xsl:variable>
	<xsl:variable name="UnitedKingdom_Nationality"><xsl:text>United Kingdom</xsl:text></xsl:variable>
	<xsl:variable name="UnitedStates_Nationality"><xsl:text>United States of America</xsl:text></xsl:variable>
	
	
	
	<xsl:variable name="DATE_FORMAT" select="'[Y0001]-[M01]-[D01]'" as="xs:string"/>


	<xsl:variable name="ADDRESS_LENGTH" select="20"/>	
	<xsl:variable name="CHECKING_MAP_NAME"><xsl:text>Banking Deposit Code For Checking</xsl:text></xsl:variable>
	<xsl:variable name="SAVINGS_MAP_NAME"><xsl:text>Banking Deposit Code For Saving</xsl:text></xsl:variable>

	<xsl:variable name="recordNode" select="/peci:Record"/>

	<xsl:template match="/">


			<adp:Payee>
			
				
			<xsl:for-each-group select="/peci:Record/peci:Worker/peci:Effective_Change" group-by="peci:Effective_Moment">
				<xsl:sort select="peci:Effective_Moment"/>
					
					<xsl:variable name="changeRecord" select="."/>

					<xsl:variable name="employeeStatus" select="this:employment-status($changeRecord)"/>

					<xsl:choose>

						<!-- Processing a new Hire or employee recently changed into this Payroll Company -->
						<xsl:when test="peci:Derived_Event_Code = 'HIR'">
							<xsl:call-template name="createEmployeeChangeRecord">
								<xsl:with-param name="changeRecord" select="$changeRecord"/>
								<xsl:with-param name="employeeStatus" select="$employeeStatus"/>
								<xsl:with-param name="effectiveDate" select="$changeRecord/peci:Worker_Status/peci:Hire_Date"/>
								<xsl:with-param name="includeJobDates" select="true()"/>
								<xsl:with-param name="includeTermInfo" select="false()"/>
								<xsl:with-param name="includePersonalInfo" select="true()"/>
								<xsl:with-param name="includeIdentifierInfo" select="true()"/>
								<xsl:with-param name="includeContactInfo" select="true()"/>
								<xsl:with-param name="includeJobInfo" select="true()"/>
								<xsl:with-param name="includeCompInfo" select="true()"/>
								<xsl:with-param name="includeLeaveInfo" select="false()"/>
								<xsl:with-param name="includeTaxInfo" select="true()"/>
							</xsl:call-template>

						</xsl:when>


						<!-- Employee recently changed into this Payroll Company -->
						<xsl:when test="peci:Derived_Event_Code = 'PCI' or peci:Derived_Event_Code = 'TERM-R'">
							<xsl:call-template name="createEmployeeChangeRecord">
								<xsl:with-param name="changeRecord" select="$changeRecord"/>
								<xsl:with-param name="employeeStatus" select="$employeeStatus"/>
								<xsl:with-param name="effectiveDate" select="substring($changeRecord/peci:Effective_Moment,1,10)"/>
								<xsl:with-param name="includeJobDates" select="true()"/>
								<xsl:with-param name="includeIdentifierInfo" select="true()"/>
								<xsl:with-param name="includeTermInfo" select="false()"/>
								<xsl:with-param name="includePersonalInfo" select="true()"/>
								<xsl:with-param name="includeContactInfo" select="true()"/>
								<xsl:with-param name="includeJobInfo" select="true()"/>
								<xsl:with-param name="includeCompInfo" select="true()"/>
								<xsl:with-param name="includeLeaveInfo" select="true()"/>
								<xsl:with-param name="includeTaxInfo" select="true()"/>
							</xsl:call-template>

						</xsl:when>

						<!-- Terminations -->
						<xsl:when test="peci:Derived_Event_Code = 'TERM'">
							<xsl:call-template name="createEmployeeChangeRecord">
								<xsl:with-param name="changeRecord" select="$changeRecord"/>
								<xsl:with-param name="employeeStatus" select="$employeeStatus"/>
								<xsl:with-param name="effectiveDate" select="$changeRecord/peci:Worker_Status/peci:Termination_Date"/>
								<xsl:with-param name="includeJobDates" select="false()"/>
								<xsl:with-param name="includeTermInfo" select="true()"/>
								<xsl:with-param name="includeIdentifierInfo" select="false()"/>
								<xsl:with-param name="includePersonalInfo" select="false()"/>
								<xsl:with-param name="includeContactInfo" select="true()"/>
								<xsl:with-param name="includeJobInfo" select="false()"/>
								<xsl:with-param name="includeCompInfo" select="false()"/>
								<xsl:with-param name="includeLeaveInfo" select="false()"/>
								<xsl:with-param name="includeTaxInfo" select="false()"/>
							</xsl:call-template>
						</xsl:when>
	
						<!-- Employee Transferring out -->
						<xsl:when test="peci:Derived_Event_Code = 'PCO' or peci:Derived_Event_Code='PGO'">
						
						
						
							<xsl:call-template name="createEmployeeChangeRecord">
								<xsl:with-param name="changeRecord" select="$changeRecord"/>
								<xsl:with-param name="effectiveDate" select="substring($changeRecord/peci:Effective_Moment,1,10)"/>
								<xsl:with-param name="employeeStatus" select="$employeeStatus"/>
								<xsl:with-param name="includeJobDates" select="false()"/>
								<xsl:with-param name="includeTermInfo" select="true()"/>
								<xsl:with-param name="includePersonalInfo" select="false()"/>
								<xsl:with-param name="includeIdentifierInfo" select="false()"/>
								<xsl:with-param name="includeContactInfo" select="true()"/>
								<xsl:with-param name="includeJobInfo" select="false()"/>
								<xsl:with-param name="includeCompInfo" select="false()"/>
								<xsl:with-param name="includeLeaveInfo" select="false()"/>
								<xsl:with-param name="includeTaxInfo" select="false()"/>
							</xsl:call-template>

						</xsl:when>

						<!-- DTA: All Other Changes -->
						<xsl:otherwise>

							<xsl:variable name="effectiveDate">
								<xsl:choose>
									<xsl:when test="$changeRecord/peci:Test = 'false'">
									</xsl:when>

									<xsl:otherwise>
										<xsl:value-of select="substring($changeRecord/peci:Effective_Moment,1,10)"/>
									</xsl:otherwise>
								</xsl:choose>

							</xsl:variable>

							<xsl:call-template name="createEmployeeChangeRecord">
								<xsl:with-param name="changeRecord" select="$changeRecord"/>
								<xsl:with-param name="employeeStatus" select="$employeeStatus"/>
								<xsl:with-param name="effectiveDate" select="$effectiveDate"/>
								<xsl:with-param name="includeJobDates" select="false()"/>
								<xsl:with-param name="includeTermInfo" select="false()"/>
								<xsl:with-param name="includePersonalInfo" select="this:isSectionChanged($changeRecord/peci:Personal)"/>
								<xsl:with-param name="includeContactInfo" select="this:isSectionChanged($changeRecord/peci:Person_Communication)"/>
								<xsl:with-param name="includeIdentifierInfo" select="this:isSectionChanged($changeRecord/peci:Person_Identification)"/>
								<xsl:with-param name="includeJobInfo" select="this:isSectionChanged($changeRecord/peci:Position)"/>
								<xsl:with-param name="includeCompInfo" select="this:isSectionChanged($changeRecord/peci:Compensation)"/>
								<xsl:with-param name="includeLeaveInfo" select="this:isSectionChanged($changeRecord/peci:Leave_of_Absence)"/>
								<xsl:with-param name="includeTaxInfo" select="this:isSectionChanged($changeRecord/peci:Additional_Information/ptdf:SUI_SDI_Tax_Jurisdiction_Code)"/>
							</xsl:call-template>
						</xsl:otherwise>
						

					</xsl:choose>

					<!--Print Benefits and Earnings Separately -->
					<xsl:if test="xsd:boolean($is.IncludeBenefitInfo) = true() and xsd:boolean($ia.Split.Benefit.File) = true() and exists($changeRecord/peci:Benefits_Earnings_and_Deductions)">
						<xsl:variable name="effectiveDate">
									<xsl:value-of select="substring($changeRecord/peci:Effective_Moment,1,10)"/>
						</xsl:variable>
						<xsl:call-template name="printEarningDeductionSeparately">
							<xsl:with-param name="changeRecord" select="$changeRecord"/>
							<xsl:with-param name="effectiveDate" select="$effectiveDate"/>
						</xsl:call-template>
					</xsl:if>


					<!--Print Payment Elections Separately -->
					<xsl:if test="xsd:boolean($is.IncludeDirectDepositInfo) = true() and xsd:boolean($ia.Split.PaymentElection.File) = true() and exists($changeRecord/peci:Payment_Election)">
						<xsl:variable name="effectiveDate">
									<xsl:value-of select="substring($changeRecord/peci:Effective_Moment,1,10)"/>
						</xsl:variable>
						<xsl:call-template name="printPaymentElectionSeparately">
							<xsl:with-param name="changeRecord" select="$changeRecord"/>
							<xsl:with-param name="effectiveDate" select="$effectiveDate"/>
						</xsl:call-template>
					</xsl:if>
			</xsl:for-each-group>
			</adp:Payee>



	</xsl:template>

	<xsl:template name="createEmployeeChangeRecord">
		<xsl:param name="changeRecord"/>
		<xsl:param name="employeeStatus"/>
		<xsl:param name="effectiveDate"/>
		<xsl:param name="includeJobDates" select="false()"/>
		<xsl:param name="includeTermInfo" select="false()"/>
		<xsl:param name="includePersonalInfo" select="false()"/>
		<xsl:param name="includeIdentifierInfo" select="false()"/>
		<xsl:param name="includeContactInfo" select="false()"/>
		<xsl:param name="includeJobInfo" select="false()"/>
		<xsl:param name="includeCompInfo" select="false()"/>
		<xsl:param name="includeLeaveInfo" select="false()"/>
		<xsl:param name="includeTaxInfo" select="false()"/>

		<xsl:variable name="includeDTARecordInOutput">
			<xsl:choose>
				<xsl:when test="this:isSectionChanged($changeRecord/peci:Personal) = true()">
					<xsl:value-of select="true()"/>
				</xsl:when>
				<xsl:when test="this:isSectionChanged($changeRecord/peci:Person_Communication) = true()">
					<xsl:value-of select="true()"/>
				</xsl:when>
				
				<xsl:when test="this:isSectionChanged($changeRecord/peci:Person_Identification) = true()">
				<xsl:value-of select="true()"/>
				</xsl:when>
				
				<xsl:when test="this:isSectionChanged($changeRecord/peci:Position) = true()">
					<xsl:value-of select="true()"/>
				</xsl:when>
				<xsl:when test="this:isSectionChanged($changeRecord/peci:Compensation) = true()">
					<xsl:value-of select="true()"/>
				</xsl:when>
				<xsl:when test="this:isSectionChanged($changeRecord/peci:Leave_of_Absence) = true()">
					<xsl:value-of select="true()"/>
				</xsl:when>
				<xsl:when test="this:isSectionChanged($changeRecord/peci:Additional_Information/ptdf:SUI_SDI_Tax_Jurisdiction_Code) = true()">
					<xsl:value-of select="true()"/>
				</xsl:when>
				<xsl:when test="$changeRecord/peci:Derived_Event_Code = 'PCO'">
				 	<xsl:value-of select="true()"/>
				 </xsl:when>
				 <xsl:when test="$changeRecord/peci:Derived_Event_Code = 'PGO'">
				 	<xsl:value-of select="true()"/>
				 </xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="false()"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:if test="$includeDTARecordInOutput = true()">
		
			<adp:ChangeRecord>
				<xsl:call-template name="employeeIdentifier"/>
	
				<!-- Only Include Effective Date only if Effective Stating is Enabled in ADP -->
				<xsl:if test="xsd:boolean($ia.EffecitveDatingEnabled) = true()">
					<adp:Change_Effective_On>
						<xsl:value-of select="this:format-Date($effectiveDate)"/>
					</adp:Change_Effective_On>
				</xsl:if>
	
				<adp:Employee_Status>
					<xsl:value-of select="$employeeStatus"/>
				</adp:Employee_Status>
	
				<xsl:call-template name="printHireInfo">
					<xsl:with-param name="changeRecord" select="$changeRecord"/>
					<xsl:with-param name="includeJobDates" select="$includeJobDates"/>
				</xsl:call-template>
	
				<xsl:call-template name="printTerminationInfo">
					<xsl:with-param name="changeRecord" select="$changeRecord"/>
					<xsl:with-param name="includeTermInfo" select="$includeTermInfo"/>
				</xsl:call-template>
	
				<!--<xsl:call-template name="printLOARFLInfo">
					<xsl:with-param name="changeRecord" select="$changeRecord"/>
					<xsl:with-param name="includeLeaveInfo" select="$includeLeaveInfo"/>
				</xsl:call-template>-->
	
				<xsl:call-template name="printPersonalData">
					<xsl:with-param name="changeRecord" select="$changeRecord"/>
					<xsl:with-param name="includePersonalInfo" select="$includePersonalInfo"/>
				</xsl:call-template>
				
				<xsl:call-template name="printIdentificationData">
					<xsl:with-param name="changeRecord" select="$changeRecord"/>
					<xsl:with-param name="includeIdentifierInfo" select="$includeIdentifierInfo"/>
				</xsl:call-template>
	
				<xsl:call-template name="printContactData">
					<xsl:with-param name="changeRecord" select="$changeRecord"/>
					<xsl:with-param name="includeContactInfo" select="$includeContactInfo"/>
				</xsl:call-template>
				
				<xsl:call-template name="printTaxInfo">
					<xsl:with-param name="changeRecord" select="$changeRecord"/>
					<xsl:with-param name="includeTaxInfo" select="$includeTaxInfo"/>
				</xsl:call-template>			
	
				<xsl:call-template name="printJobInfo">
					<xsl:with-param name="changeRecord" select="$changeRecord"/>
					<xsl:with-param name="includeJobInfo" select="$includeJobInfo"/>
				</xsl:call-template>
	
				<xsl:call-template name="printCompensationInfo">
					<xsl:with-param name="changeRecord" select="$changeRecord"/>
					<xsl:with-param name="includeCompInfo" select="$includeCompInfo"/>
				</xsl:call-template>
	
				<xsl:if test="xsd:boolean($is.IncludeBenefitInfo) = true() and xsd:boolean($ia.Split.Benefit.File) = false()">
				    <xsl:call-template name="createEmptyBenefit"/>
				 </xsl:if>  
				 
				 <xsl:if test="xsd:boolean($is.IncludeDirectDepositInfo) = true() and xsd:boolean($ia.Split.PaymentElection.File) = false()">
					<xsl:call-template name="createEmptyPaymentElection"/>
				 </xsl:if>
	
			</adp:ChangeRecord>
		</xsl:if>
		
		<xsl:if test="xsd:boolean($is.IncludeBenefitInfo) = true() and xsd:boolean($ia.Split.Benefit.File) = false() and exists($changeRecord/peci:Benefits_Earnings_and_Deductions)">
			<xsl:call-template name="printEarningDeductionInMaster">
				<xsl:with-param name="changeRecord" select="$changeRecord"/>
				<xsl:with-param name="effectiveDate" select="$effectiveDate"/>
				<xsl:with-param name="employeeStatus" select="$employeeStatus"/>
			</xsl:call-template>
		</xsl:if>	
		
		<xsl:if test="xsd:boolean($is.IncludeDirectDepositInfo) = true() and xsd:boolean($ia.Split.PaymentElection.File) = false() and exists($changeRecord/peci:Payment_Election)">
			<xsl:call-template name="printPaymentElectionInMaster">
				<xsl:with-param name="changeRecord" select="$changeRecord"/>
				<xsl:with-param name="effectiveDate" select="$effectiveDate"/>
				<xsl:with-param name="employeeStatus" select="$employeeStatus"/>
			</xsl:call-template>
		</xsl:if>		
			
	</xsl:template>

	<xsl:template name="printHireInfo">
		<xsl:param name="changeRecord"/>
		<xsl:param name="includeJobDates"/>


		<xsl:choose>
			<xsl:when test="$includeJobDates = true()">
				<adp:Hire_Date>
					<xsl:value-of select="this:format-Date($changeRecord/peci:Worker_Status/peci:Hire_Date)"/>
				</adp:Hire_Date>
				
				<adp:Original_Hire_Date>
				<xsl:value-of select="this:format-Date($changeRecord/peci:Worker_Status/peci:Original_Hire_Date)"/>
				
				</adp:Original_Hire_Date>
				<adp:Rehire_Date>
					<xsl:if test="exists($changeRecord/peci:Worker_Status/peci:Original_Hire_Date) and $changeRecord/peci:Worker_Status/peci:Original_Hire_Date ne $changeRecord/peci:Worker_Status/peci:Hire_Date
					 and $changeRecord/peci:Worker_Status/peci:Original_Hire_Date &lt; $changeRecord/peci:Worker_Status/peci:Hire_Date">
						<xsl:value-of select="this:format-Date($changeRecord/peci:Worker_Status/peci:Hire_Date)"/>
					</xsl:if>
				</adp:Rehire_Date>		
			</xsl:when>
			<xsl:otherwise>
				<adp:Hire_Date/>
				<adp:Original_Hire_Date/>
				<adp:Rehire_Date/>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>

	<xsl:template name="printTerminationInfo">
		<xsl:param name="changeRecord"/>
		<xsl:param name="includeTermInfo"/>

		<xsl:choose>
			<xsl:when test="$includeTermInfo = true()">
				<adp:Termination_Date>
				 <xsl:variable name="DATE" select="peci:Effective_Moment"/>
                    <xsl:variable name="FORMAT" select="format-dateTime($DATE, $DATE_FORMAT)"/>
                    
				
					<xsl:choose>						
						<xsl:when test="$changeRecord/peci:Derived_Event_Code = 'PCO' or $changeRecord/peci:Derived_Event_Code = 'PGO'">
							   <xsl:value-of select="xs:date($FORMAT) - xs:dayTimeDuration('P1D')"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="this:format-Date($changeRecord/peci:Worker_Status/peci:Termination_Date)"/>
						</xsl:otherwise>
					</xsl:choose>					
				</adp:Termination_Date>
			
				<adp:Termination_Reason>
					<xsl:value-of select="$changeRecord/peci:Worker_Status/peci:Primary_Termination_Reason"/>
				</adp:Termination_Reason>	
				
				<adp:Pay_Through_Date>
				<xsl:value-of select="this:format-Date($changeRecord/peci:Worker_Status/peci:Pay_Through_Date)"/>
				</adp:Pay_Through_Date>
			</xsl:when>
			<xsl:otherwise>
				<adp:Termination_Date/>
				<adp:Termination_Reason/>
				<adp:Pay_Through_Date/>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>

	<xsl:template name="printPersonalData">
		<xsl:param name="changeRecord"/>
		<xsl:param name="includePersonalInfo"/>


		<xsl:choose>
			<xsl:when test="$includePersonalInfo = true()">

				<adp:Birth_Date>
					<xsl:value-of select="this:format-Date($changeRecord/peci:Personal/peci:Date_of_Birth)"/>
				</adp:Birth_Date>
			
				<xsl:choose>
					<xsl:when test="string-length($changeRecord/peci:Person_Identification/peci:National_Identifier[peci:National_ID_Type = 'USA-SSN']/peci:National_ID) > 0">
						<adp:Tax_ID_Type>
							<xsl:text>SSN</xsl:text>
						</adp:Tax_ID_Type>
						<adp:Tax_ID_Number>
							<xsl:value-of select="$changeRecord/peci:Person_Identification/peci:National_Identifier[peci:National_ID_Type = 'USA-SSN']/peci:National_ID"/>
						</adp:Tax_ID_Number>
					</xsl:when>
					<xsl:otherwise>
						<adp:Tax_ID_Type/>
						<adp:Tax_ID_Number/>
					</xsl:otherwise>
				</xsl:choose>

				<adp:First_Name>
					<xsl:choose>
						<xsl:when test="string-length($changeRecord/peci:Personal/peci:Legal_Name/peci:Middle_Name) > 0">
							<xsl:value-of select="concat($changeRecord/peci:Personal/peci:Legal_Name/peci:First_Name, ' ',$changeRecord/peci:Personal/peci:Legal_Name/peci:Middle_Name)"/> 
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$changeRecord/peci:Personal/peci:Legal_Name/peci:First_Name"/>
						</xsl:otherwise>
					</xsl:choose>
						
				</adp:First_Name>

				<adp:Last_Name>
					<xsl:value-of select="$changeRecord/peci:Personal/peci:Legal_Name/peci:Last_Name"/>
				</adp:Last_Name>
			
				<adp:Preferred_Name>
					<xsl:value-of select="$changeRecord/peci:Personal/peci:Preferred_Name/peci:First_Name"/>
				</adp:Preferred_Name>

				<adp:Gender>
					<xsl:value-of select="$changeRecord/peci:Personal/peci:Gender"/>
				</adp:Gender>
			
				<adp:Race>
					<xsl:value-of select="$changeRecord/peci:Personal/peci:Ethnicity[not(exists(@peci:isDeleted))]/peci:Ethnicity_ID"/>
				</adp:Race>
				
				<adp:Marital_Status>
					<xsl:choose>
						<xsl:when test="string-length($changeRecord/peci:Personal/peci:Marital_Status) = 0">
							<xsl:text>~</xsl:text> 
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$changeRecord/peci:Personal/peci:Marital_Status"/>
						</xsl:otherwise>
					</xsl:choose>
				
				</adp:Marital_Status>
				
				<adp:Citizenship_Status>
				<xsl:value-of select="$changeRecord/peci:Personal/peci:Citizenship[not(exists(@peci:isDeleted))]/peci:Citizenship_Status_ID"/>
				
				</adp:Citizenship_Status>
			
				
				<adp:Nationality>
			<xsl:choose>
                        <xsl:when
                            test="$changeRecord/peci:Personal/peci:Nationality = 'AU'">
                            <xsl:value-of
                                select="$Australia_Nationality"/>
                        </xsl:when>
                        <xsl:otherwise> </xsl:otherwise>
                    </xsl:choose>
                        <xsl:choose>
                        <xsl:when
                            test="$changeRecord/peci:Personal/peci:Nationality = 'BE'">
                            <xsl:value-of
                                select="$Belgium_Nationality"/>
                        </xsl:when>
                        <xsl:otherwise> </xsl:otherwise>
                    </xsl:choose>
                          <xsl:choose>
                        <xsl:when
                            test="$changeRecord/peci:Personal/peci:Nationality = 'BR'">
                            <xsl:value-of
                                select="$Brazil_Nationality"/>
                        </xsl:when>
                        <xsl:otherwise> </xsl:otherwise>
                    </xsl:choose>
                          <xsl:choose>
                        <xsl:when
                            test="$changeRecord/peci:Personal/peci:Nationality = 'EE'">
                            <xsl:value-of
                                select="$Estonia_Nationality"/>
                        </xsl:when>
                        <xsl:otherwise> </xsl:otherwise>
                    </xsl:choose>
                           <xsl:choose>
                        <xsl:when
                            test="$changeRecord/peci:Personal/peci:Nationality = 'HK'">
                            <xsl:value-of
                                select="$HongKong_Nationality"/>
                        </xsl:when>
                        <xsl:otherwise> </xsl:otherwise>
                    </xsl:choose>
                             <xsl:choose>
                        <xsl:when
                            test="$changeRecord/peci:Personal/peci:Nationality = 'HU'">
                            <xsl:value-of
                                select="$Hungary_Nationality"/>
                        </xsl:when>
                        <xsl:otherwise> </xsl:otherwise>
                    </xsl:choose>
                             <xsl:choose>
                        <xsl:when
                            test="$changeRecord/peci:Personal/peci:Nationality = 'ID'">
                            <xsl:value-of
                                select="$Indonesia_Nationality"/>
                        </xsl:when>
                        <xsl:otherwise> </xsl:otherwise>
                    </xsl:choose>
                               <xsl:choose>
                        <xsl:when
                            test="$changeRecord/peci:Personal/peci:Nationality = 'JP'">
                            <xsl:value-of
                                select="$Japan_Nationality"/>
                        </xsl:when>
                        <xsl:otherwise> </xsl:otherwise>
                    </xsl:choose>
                              <xsl:choose>
                        <xsl:when
                            test="$changeRecord/peci:Personal/peci:Nationality = 'MY'">
                            <xsl:value-of
                                select="$Malaysia_Nationality"/>
                        </xsl:when>
                        <xsl:otherwise> </xsl:otherwise>
                    </xsl:choose>
                             <xsl:choose>
                        <xsl:when
                            test="$changeRecord/peci:Personal/peci:Nationality = 'NL'">
                            <xsl:value-of
                                select="$Netherlands_Nationality"/>
                        </xsl:when>
                        <xsl:otherwise> </xsl:otherwise>
                    </xsl:choose>
                          <xsl:choose>
                        <xsl:when
                            test="$changeRecord/peci:Personal/peci:Nationality = 'SG'">
                            <xsl:value-of
                                select="$Singapore_Nationality"/>
                        </xsl:when>
                        <xsl:otherwise> </xsl:otherwise>
                    </xsl:choose>
                      <xsl:choose>
                        <xsl:when
                            test="$changeRecord/peci:Personal/peci:Nationality = 'TH'">
                            <xsl:value-of
                                select="$Thailand_Nationality"/>
                        </xsl:when>
                        <xsl:otherwise> </xsl:otherwise>
                    </xsl:choose>
                     <xsl:choose>
                        <xsl:when
                            test="$changeRecord/peci:Personal/peci:Nationality = 'UA'">
                            <xsl:value-of
                                select="$Ukraine_Nationality"/>
                        </xsl:when>
                        <xsl:otherwise> </xsl:otherwise>
                    </xsl:choose>
                     <xsl:choose>
                        <xsl:when
                            test="$changeRecord/peci:Personal/peci:Nationality = 'AE'">
                            <xsl:value-of
                                select="$UAE_Nationality"/>
                        </xsl:when>
                        <xsl:otherwise> </xsl:otherwise>
                    </xsl:choose>
                      <xsl:choose>
                        <xsl:when
                            test="$changeRecord/peci:Personal/peci:Nationality = 'GB'">
                            <xsl:value-of
                                select="$UnitedKingdom_Nationality"/>
                        </xsl:when>
                        <xsl:otherwise> </xsl:otherwise>
                    </xsl:choose>
                     <xsl:choose>
                        <xsl:when
                            test="$changeRecord/peci:Personal/peci:Nationality = 'US'">
                            <xsl:value-of
                                select="$UnitedStates_Nationality"/>
                        </xsl:when>
                        <xsl:otherwise> </xsl:otherwise>
                    </xsl:choose>
				</adp:Nationality>	
			</xsl:when>
			<xsl:otherwise>
				<adp:Birth_Date/>
				<adp:Tax_ID_Type/>
				<adp:Tax_ID_Number/>
				<adp:First_Name/>
				<adp:Last_Name/>
				<adp:Preferred_Name/>
				<adp:Gender/>
				<adp:Race/>
				<adp:Marital_Status/>
				<adp:Citizenship_Status/>
				<adp:Nationality/>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>
	
	<xsl:template name="printIdentificationData">
		<xsl:param name="changeRecord"/>
		<xsl:param name="includeIdentifierInfo"/>
		
			<xsl:choose>
					<xsl:when test="string-length($changeRecord/peci:Person_Identification/peci:Other_Identifier/peci:Custom_ID) > 0">
						<adp:Payroll_ID_Type>
						
						</adp:Payroll_ID_Type>
						<adp:Payroll_ID_Number>
							<xsl:value-of select="$changeRecord/peci:Person_Identification/peci:Other_Identifier/peci:Custom_ID"/>
						</adp:Payroll_ID_Number>
					</xsl:when>
					<xsl:otherwise>
						<adp:Payroll_ID_Type/>
						<adp:Payroll_ID_Number/>
					</xsl:otherwise>
				</xsl:choose>
				
				<xsl:choose>
					<xsl:when test="string-length($changeRecord/peci:Person_Identification/peci:Other_Identifier/peci:Custom_ID) > 0">
						<adp:Payroll_ID_Type>
						
						</adp:Payroll_ID_Type>
						<adp:Payroll_ID_Number>
							<xsl:value-of select="$changeRecord/peci:Person_Identification/peci:Other_Identifier/peci:Custom_ID"/>
						</adp:Payroll_ID_Number>
					</xsl:when>
					<xsl:otherwise>
						<adp:Payroll_ID_Type/>
						<adp:Payroll_ID_Number/>
					</xsl:otherwise>
				</xsl:choose>
                   
                    <xsl:choose>
                        <xsl:when
                            test="$pay.group.id = 'HUNGARY_PAY_GROUP'">
                            <adp:National_Identifier_1>
                            <xsl:value-of
                                select="$changeRecord/peci:Person_Identification/peci:National_Identifier[peci:National_ID_Type = 'HUN-SA']/peci:National_ID"
                            />
                            </adp:National_Identifier_1>
                        </xsl:when>
                         <xsl:when
                            test="$pay.group.id = 'UNITED_KINGDOM_PAY_GROUP'">
                            <adp:National_Identifier_1>
                            <xsl:value-of
                                select="$changeRecord/peci:Person_Identification/peci:National_Identifier[peci:National_ID_Type = 'GBR-NI']/peci:National_ID"
                            />
                            </adp:National_Identifier_1>
                        </xsl:when>
                        <xsl:when
                            test="$pay.group.id = 'ESTONIA_PAY_GROUP'">
                            <adp:National_Identifier_1>
                            <xsl:value-of
                                select="$changeRecord/peci:Person_Identification/peci:National_Identifier[peci:National_ID_Type = 'EST-IK']/peci:National_ID"
                            />
                            </adp:National_Identifier_1>
                            </xsl:when>
                                 <xsl:when test="$pay.group.id = 'UNITED_STATES_OF_AMERICA_PAY_GROUP'">
                            <adp:National_Identifier_1>
                            <xsl:value-of
                                select="$changeRecord/peci:Person_Identification/peci:National_Identifier[peci:National_ID_Type = 'USA-SSN']/peci:National_ID"
                            />
                            </adp:National_Identifier_1>
                        </xsl:when>
                           <xsl:when
                            test="$pay.group.id = 'SINGAPORE_PAY_GROUP'">
                            <adp:National_Identifier_1>
                            <xsl:value-of
                                select="$changeRecord/peci:Person_Identification/peci:National_Identifier[peci:National_ID_Type = 'SGP-NRIC']/peci:National_ID"
                            />
                            </adp:National_Identifier_1>
                        </xsl:when>
                           <xsl:when
                            test="$pay.group.id = 'AUSTRALIA_PAY_GROUP'">
                            <adp:National_Identifier_1>
                            <xsl:value-of
                                select="$changeRecord/peci:Person_Identification/peci:National_Identifier[peci:National_ID_Type = 'AUS-TFN']/peci:National_ID"
                            />
                            </adp:National_Identifier_1>
                        </xsl:when>
                           <xsl:when
                            test="$pay.group.id = 'BRAZIL_PAY_GROUP'">
                            <adp:National_Identifier_1>
                            <xsl:value-of
                                select="$changeRecord/peci:Person_Identification/peci:National_Identifier[peci:National_ID_Type = 'AUS-TFN']/peci:National_ID"
                            />
                            </adp:National_Identifier_1>
                        </xsl:when>
                            <xsl:when
                            test="$pay.group.id = 'JAPAN_PAY_GROUP'">
                            <adp:National_Identifier_1>
                            <xsl:value-of
                                select="$changeRecord/peci:Person_Identification/peci:National_Identifier[peci:National_ID_Type = 'JPN-MIN']/peci:National_ID"
                            />
                            </adp:National_Identifier_1>
                        </xsl:when>
                                <xsl:when
                            test="$pay.group.id = 'MALAYSIA_PAY_GROUP'">
                            <adp:National_Identifier_1>
                            <xsl:value-of
                                select="$changeRecord/peci:Person_Identification/peci:National_Identifier[peci:National_ID_Type = 'MYS-ID']/peci:National_ID"
                            />
                            </adp:National_Identifier_1>
                        </xsl:when>
                          <xsl:when
                            test="$pay.group.id = 'BELGIUM_PAY_GROUP'">
                            <adp:National_Identifier_1>
                            <xsl:value-of
                                select="$changeRecord/peci:Person_Identification/peci:National_Identifier[peci:National_ID_Type = 'BEL-NN']/peci:National_ID"
                            />
                            </adp:National_Identifier_1>
                        </xsl:when>
                          <xsl:when
                            test="$pay.group.id = 'HONG_KONG_PAY_GROUP'">
                            <adp:National_Identifier_1>
                            <xsl:value-of
                                select="$changeRecord/peci:Person_Identification/peci:National_Identifier[peci:National_ID_Type = 'HKG-ID']/peci:National_ID"
                            />
                            </adp:National_Identifier_1>
                        </xsl:when>
                        
                        <xsl:otherwise> 
                        <adp:National_Identifier_1/>
                        </xsl:otherwise>
                    </xsl:choose>
                 

                    
                        <xsl:choose>
                        <xsl:when
                            test="$pay.group.id = 'HUNGARY_PAY_GROUP'">
                            <adp:National_Identifier_2>
                            <xsl:value-of
                                select="$changeRecord/peci:Person_Identification/peci:National_Identifier[peci:National_ID_Type = 'HUN-TK']/peci:National_ID"
                            />
                            </adp:National_Identifier_2>
                        </xsl:when>
                        
                        <xsl:otherwise> 
                        <adp:National_Identifier_2/>
                        </xsl:otherwise>
                    </xsl:choose>
                    
                        <xsl:choose>
                        <xsl:when
                            test="$pay.group.id = 'HUNGARY_PAY_GROUP'">
                            <adp:National_Identifier_3>
                            <xsl:value-of
                                select="$changeRecord/peci:Person_Identification/peci:National_Identifier[peci:National_ID_Type = 'HUN-AK']/peci:National_ID"
                            />
                            </adp:National_Identifier_3>
                        </xsl:when>
                        
                        <xsl:otherwise> 
                        <adp:National_Identifier_3/>
                        </xsl:otherwise>
                    </xsl:choose>

		</xsl:template>

	<xsl:template name="employeeIdentifier">

		<xsl:variable name="adpFileNumber">
					<xsl:value-of select="/peci:Record/peci:Worker/peci:Worker_Summary/peci:Employee_ID"/>
		</xsl:variable>

		<adp:Emp_ID>
			<xsl:value-of select="$adpFileNumber"/>
		</adp:Emp_ID>

	</xsl:template>


	<xsl:template name="printContactData">
		<xsl:param name="changeRecord"/>
		<xsl:param name="includeContactInfo"/>


		<xsl:choose>
			<xsl:when test="$includeContactInfo = true()">
				<xsl:variable name="homeAddress" select="$changeRecord/peci:Person_Communication/peci:Address[peci:Usage_Type = 'HOME' and not(exists(@peci:isDeleted))]"/>
				<xsl:variable name="phoneNumber" select="$changeRecord/peci:Person_Communication/peci:Phone[not(exists(@peci:isDeleted))][1]"/>
				<xsl:variable name="emailAddress" select="$changeRecord/peci:Person_Communication/peci:Email[peci:Usage_Type = 'HOME' and  not(exists(@peci:isDeleted))]"/>

				<adp:Home_Phone_Number><xsl:value-of select="this:editHomePhoneNumber($phoneNumber)"/></adp:Home_Phone_Number>
	
				<adp:Home_E-mail><xsl:value-of select="$emailAddress/peci:Email_Address"/></adp:Home_E-mail>
						
				
				<!--<adp:Address_1_Line_1>
					<xsl:value-of select="this:setAddress1($homeAddress/peci:Address_Line_1, $homeAddress/peci:Address_Line_2)"/>
				</adp:Address_1_Line_1>
				<adp:Address_1_Line_2>
					<xsl:value-of select="this:setAddress2($homeAddress/peci:Address_Line_1, $homeAddress/peci:Address_Line_2)"/>
				</adp:Address_1_Line_2>
				<adp:Address_1_City><xsl:value-of select="$homeAddress/peci:City"/></adp:Address_1_City>
				<adp:Address_1_State_Postal_Code>
					<xsl:value-of select="$changeRecord/peci:Person_Communication/ptdf:Home_Address_State"/>
				</adp:Address_1_State_Postal_Code>
				<adp:Address_1_Zip_Code>
					<xsl:value-of select="$homeAddress/peci:Postal_Code"/>
				</adp:Address_1_Zip_Code>-->
				
				<adp:Address_1_Line_1>
					<xsl:value-of select="$homeAddress/peci:Address_Line_1"/>
				</adp:Address_1_Line_1>
				<adp:Address_1_Line_2>
					<xsl:value-of select="$homeAddress/peci:Address_Line_2"/>
				</adp:Address_1_Line_2>
				<adp:Address_1_Line_3>
					<xsl:value-of select="$homeAddress/peci:Address_Line_3"/>
				</adp:Address_1_Line_3>
				<adp:Address_1_Line_4>
					<xsl:value-of select="$homeAddress/peci:Address_Line_4"/>
				</adp:Address_1_Line_4>
				<adp:Address_1_Line_5>
					<xsl:value-of select="$homeAddress/peci:Address_Line_5"/>
				</adp:Address_1_Line_5>
				<adp:Address_1_Line_6>
					<xsl:value-of select="$homeAddress/peci:Address_Line_6"/>
				</adp:Address_1_Line_6>
				<adp:Address_1_Line_7>
					<xsl:value-of select="$homeAddress/peci:Address_Line_7"/>
				</adp:Address_1_Line_7>
				<adp:Address_1_Line_8>
					<xsl:value-of select="$homeAddress/peci:Address_Line_8"/>
				</adp:Address_1_Line_8>
				<adp:Address_1_Line_9>
					<xsl:value-of select="$homeAddress/peci:Address_Line_9"/>
				</adp:Address_1_Line_9>
				<adp:Address_1_State>
 				<xsl:value-of select="$homeAddress/peci:State_Province"/>
 				</adp:Address_1_State>
				<adp:Address_1_City>
					<xsl:value-of select="$homeAddress/peci:City"/>
				</adp:Address_1_City>
				<adp:Address_1_Postcode>
					<xsl:value-of select="$homeAddress/peci:Postal_Code"/>
				</adp:Address_1_Postcode>
			
			</xsl:when>
			<xsl:otherwise>
				<adp:Home_Phone_Number/>
				<adp:Home_Email/>
				<adp:Address_1_Line_1/>
				<adp:Address_1_Line_2/>
				<adp:Address_1_Line_3/>
				<adp:Address_1_Line_4/>
				<adp:Address_1_Line_5/>
				<adp:Address_1_Line_6/>
				<adp:Address_1_Line_7/>
				<adp:Address_1_Line_8/>
				<adp:Address_1_Line_9/>
				<adp:Address_1_City/>
				<adp:Address_1_Postcode/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="printJobInfo">
		<xsl:param name="changeRecord"/>
		<xsl:param name="includeJobInfo"/>

		<xsl:variable name="currentPosition" select="$changeRecord/peci:Position[peci:Primary_Job = '1']"/>
		<!-- and peci:Operation ne 'REMOVE' -->
										 
		
		<xsl:variable name="previousPosition" select="$changeRecord/peci:Position[peci:Operation = 'REMOVE']"/>

		<xsl:choose>
			<xsl:when test="$includeJobInfo = true() and exists($changeRecord/peci:Position[peci:Primary_Job = '1'])">
				<adp:Location>
					<xsl:value-of select="$currentPosition/peci:Business_Site/peci:Location_Name"/>
				</adp:Location>
				
				<adp:Scheduled_Weekly_Hours>
				<xsl:value-of select="$currentPosition/peci:Scheduled_Weekly_Hours"/>
				
				</adp:Scheduled_Weekly_Hours>
				
				<adp:FTE>
				<xsl:value-of select="$currentPosition/peci:Full_Time_Equivalent_Percentage"/>
				
				</adp:FTE>
								
				<adp:Business_Title>
					<xsl:value-of select="$currentPosition/peci:Business_Title"/>
				</adp:Business_Title>	
			
				<adp:SUPERVISORID>
					<xsl:variable name="supervisorName" select="$currentPosition/ptdf:Supervisor_ADP_Position_ID"/>
					<xsl:value-of select="$supervisorName"/>
				
				</adp:SUPERVISORID>	
			
				<adp:Standard_Hours>
					<xsl:choose>
						<xsl:when test="string-length($currentPosition/peci:Pay_Cycle_Hours) > 0 and $currentPosition/peci:Pay_Rate_Type != 'H'">
							<xsl:value-of select="format-number(number($currentPosition/peci:Pay_Cycle_Hours), '#00.00')"/>
						</xsl:when>	
						<xsl:otherwise>
							<xsl:text>~</xsl:text>
						</xsl:otherwise>				
					</xsl:choose>

				</adp:Standard_Hours>	
			
				<adp:Workers_Comp_Code><xsl:value-of select="$currentPosition/peci:Workers_Compensation_Code"/></adp:Workers_Comp_Code>
							

				<adp:FLSA_Code>
					<xsl:choose>
						<xsl:when test="$currentPosition/peci:Job_Exempt = '1'"> 
							<xsl:text>E</xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text>N</xsl:text>
						</xsl:otherwise>
					</xsl:choose>
				</adp:FLSA_Code>		

			
				<adp:Pay_Group>
					<xsl:value-of select="$pay.group.id"/>
				</adp:Pay_Group>
			
			
				<adp:Shift>
					<xsl:value-of select="$currentPosition/peci:Work_Shift"/>
				</adp:Shift>			
			
				<adp:Employee_Type>
					<xsl:value-of select="$currentPosition/peci:Position_Time_Type"/>
				</adp:Employee_Type>
				
				<adp:Cost_Center_Name>
 					<xsl:value-of select="$currentPosition/peci:Organization[not(exists(@peci:isDeleted))]/peci:Organization_Name"/>
				 </adp:Cost_Center_Name>
 
 				<adp:Cost_Center_Code>
 					<xsl:value-of select="$currentPosition/peci:Organization[not(exists(@peci:isDeleted))]/peci:Organization_Code"/>
				 </adp:Cost_Center_Code>
				 
			</xsl:when>
			<xsl:otherwise>
				<adp:Location/>
				<adp:Scheduled_Weekly_Hours/>
				<adp:FTE/>
				<adp:Business_Title/>
				<adp:SUPERVISORID/>
				<adp:Standard_Hours/>
				<adp:Workers_Comp_Code/>
				<adp:FLSA_Code/>
				<adp:Pay_Group/>
				<adp:Shift/>
				<adp:Employee_Type/>
				<adp:Cost_Center_Name/>
				<adp:Cost_Center_Code/>

			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="printCompensationInfo">
		<xsl:param name="changeRecord"/>
		<xsl:param name="includeCompInfo"/>
	
		<xsl:variable name="compensationNode" select="$changeRecord/peci:Compensation"/>

		<xsl:variable name="currentPosition" select="$changeRecord/peci:Position[peci:Primary_Job = '1']"/>

		<xsl:choose>
			<xsl:when test="$includeCompInfo = true() and exists($changeRecord/peci:Compensation)">
				<adp:Pay_Frequency_Code>
					<xsl:value-of select="$compensationNode/peci:Compensation_Summary_Based_on_Compensation_Grade/peci:Frequency"/>
				</adp:Pay_Frequency_Code>
				
				<adp:Currency>
					<xsl:value-of select="$compensationNode/peci:Compensation_Summary_Based_on_Compensation_Grade/peci:Currency"/>
				</adp:Currency>
				

				<adp:Primary_Rate_Effective_Date>
					<xsl:value-of select="this:format-Date(substring($changeRecord/peci:Effective_Moment,1,10))"/>
				</adp:Primary_Rate_Effective_Date> 
				<adp:Rate_1_Amount>
					<xsl:value-of select="format-number(number($compensationNode/peci:Compensation_Summary_Based_on_Compensation_Grade/peci:Total_Base_Pay),'####0.0000')"/>	
				</adp:Rate_1_Amount>			
				<adp:Rate_Type>
					<xsl:value-of select="$compensationNode/ptdf:Pay_Rate_Type"/>
				</adp:Rate_Type>
				<adp:Compensation_Change_Reason></adp:Compensation_Change_Reason>
			</xsl:when>
			<xsl:otherwise>
				<adp:Pay_Frequency_Code/>
				<adp:Currency/>
				<adp:Primary_Rate_Effective_Date/>
				<adp:Rate_1_Amount/>
				<adp:Rate_Type/>
				<adp:Compensation_Change_Reason/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!--<xsl:template name="printLOARFLInfo">
		<xsl:param name="changeRecord"/>
		<xsl:param name="includeLeaveInfo"/>

		<xsl:variable name="employeeStatus" select="this:employment-status($changeRecord)"/>

		<!-\- In care there are multiple LOA instances -\->
		<xsl:for-each select="$changeRecord/peci:Leave_of_Absence[not(exists(peci:isDeleted)) and peci:On_Leave ne'1']">
			<xsl:choose>
				<xsl:when test="$includeLeaveInfo = true()">
					<adp:Leave_Of_Absence_Start_Date>
						<xsl:if test="$employeeStatus != 'T'">
							<xsl:value-of select="this:format-Date(peci:Leave_Start_Date)"/>
						</xsl:if>
					</adp:Leave_Of_Absence_Start_Date>		
				
					<adp:Leave_Of_Absence_Return_Date/>

				</xsl:when>
				<xsl:otherwise>
					<adp:Leave_Of_Absence_Start_Date/>
					<adp:Leave_Of_Absence_Return_Date/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
		
		<!-\- In care there are multiple RFL instances -\->
		<xsl:for-each select="$changeRecord/peci:Leave_of_Absence[not(exists(peci:isDeleted)) and peci:On_Leave eq'1']">
			<xsl:choose>
				<xsl:when test="$includeLeaveInfo = true()">
					<adp:Leave_Of_Absence_Start_Date>
						<xsl:if test="$employeeStatus != 'T'">
							<xsl:value-of select="this:format-Date(peci:Leave_Start_Date)"/>
						</xsl:if>
					</adp:Leave_Of_Absence_Start_Date>		
				
					<adp:Leave_Of_Absence_Return_Date>
						<xsl:choose>
							<xsl:when test="/peci:Employee/peci:Status/peci:Staffing_Event = 'RFL'"> 
								<xsl:value-of select="this:format-Date($changeRecord/peci:Status/peci:Staffing_Event_Date)"/>
							</xsl:when>
							<xsl:when test="exists($changeRecord/peci:Leave_of_Absence[peci:On_Leave ='1']) = true()">
								<xsl:value-of select="this:format-Date(peci:Leave_End_Date)"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:text/>
							</xsl:otherwise>
						</xsl:choose>
					
					</adp:Leave_Of_Absence_Return_Date>
				</xsl:when>
				<xsl:otherwise>
					<adp:Leave_Of_Absence_Start_Date/>
					<adp:Leave_Of_Absence_Return_Date/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>		
	</xsl:template>-->

	<xsl:template name="printTaxInfo">
		<xsl:param name="changeRecord"/>
		<xsl:param name="includeTaxInfo"/>


		<xsl:choose>
			<xsl:when test="$includeTaxInfo = true()">

				<adp:SUI_SDI_Tax_Jurisdiction_Code columnHeading="SUI/SDI Tax Jurisdiction Code">
					<xsl:value-of select="$changeRecord/peci:Additional_Information/ptdf:SUI_SDI_Tax_Jurisdiction_Code"/>
				</adp:SUI_SDI_Tax_Jurisdiction_Code>	
				<adp:Federal_Exemptions></adp:Federal_Exemptions>
				<adp:Federal_Marital_Status></adp:Federal_Marital_Status>
			</xsl:when>
			<xsl:otherwise>
				<adp:SUI_SDI_Tax_Jurisdiction_Code columnHeading="SUI/SDI Tax Jurisdiction Code"/>
				<adp:Federal_Exemptions/>
				<adp:Federal_Marital_Status/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>



	<xsl:template name="createEmptyMaster">
		<xsl:param name="changeRecord"/>

		<xsl:call-template name="printHireInfo">
			<xsl:with-param name="changeRecord" select="$changeRecord"/>
			<xsl:with-param name="includeJobDates" select="false()"/>
		</xsl:call-template>

		<xsl:call-template name="printTerminationInfo">
			<xsl:with-param name="changeRecord" select="$changeRecord"/>
			<xsl:with-param name="includeTermInfo" select="false()"/>
		</xsl:call-template>

		<!--<xsl:call-template name="printLOARFLInfo">
			<xsl:with-param name="changeRecord" select="$changeRecord"/>
			<xsl:with-param name="includeLeaveInfo" select="false()"/>
		</xsl:call-template>-->

		<xsl:call-template name="printPersonalData">
			<xsl:with-param name="changeRecord" select="$changeRecord"/>
			<xsl:with-param name="includePersonalInfo" select="false()"/>
		</xsl:call-template>
		
			<xsl:call-template name="printIdentificationData">
			<xsl:with-param name="changeRecord" select="$changeRecord"/>
			<xsl:with-param name="includeIdentifierInfo" select="false()"/>
		</xsl:call-template>

		<xsl:call-template name="printContactData">
			<xsl:with-param name="changeRecord" select="$changeRecord"/>
			<xsl:with-param name="includeContactInfo" select="false()"/>
		</xsl:call-template>

		<xsl:call-template name="printJobInfo">
			<xsl:with-param name="changeRecord" select="$changeRecord"/>
			<xsl:with-param name="includeJobInfo" select="false()"/>
		</xsl:call-template>

		<xsl:call-template name="printCompensationInfo">
			<xsl:with-param name="changeRecord" select="$changeRecord"/>
			<xsl:with-param name="includeCompInfo" select="false()"/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template name="createEmptyBenefit">	

	    <adp:Additional_Earnings_Code/>
	    <adp:Additional_Earnings_Amount/>
	    <adp:Deduction_Code/>
	    <adp:Deduction_Amount/>
	    <Deduction_Factor/>
	    
	</xsl:template>
	
	<xsl:template name="createEmptyPaymentElection"> 

		<adp:Bank_Deposit_Position_Number/>
		<adp:Bank_Deposit_Deduction_Code columnHeading="Bank Deposit Deduction Code"/>
		<adp:Bank_Full_Deposit_Flag columnHeading="Bank Full Deposit Flag"/>
		<adp:Bank_Deposit_Deduction_Amount columnHeading="Bank Deposit Deduction Amount"/>
		<adp:Bank_Deposit_Account_Number columnHeading="Bank Deposit Account Number"/>
		<adp:Bank_Deposit_Transit_ABA columnHeading="Bank Deposit Transit/ABA"/>
					
	</xsl:template>
	
	<xsl:template name="printCustomFieldInfo">
		<xsl:param name="changeRecord"/>
		<xsl:param name="includeCompInfo"/>


		<xsl:choose>
			<xsl:when test="$includeCompInfo = true()">
			</xsl:when>
			<xsl:otherwise>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>


	<xsl:template name="printEarningDeductionSeparately">
		<xsl:param name="changeRecord"/>
		<xsl:param name="effectiveDate"/>
		<xsl:param name="employeeStatus"/>

		<adp:EarningsAndDeductions>	
			<xsl:for-each select="$changeRecord/peci:Benefits_Earnings_and_Deductions">
				<xsl:if test="this:includeEarnDedInOutput(.) = true()">
					<adp:EarningsAndDeduction>
						<xsl:call-template name="employeeIdentifier"/>
	
						<xsl:if test="xsd:boolean($ia.EffecitveDatingEnabled) = true()">
							<adp:Change_Effective_On>
								<xsl:value-of select="this:format-Date($effectiveDate)"/>
							</adp:Change_Effective_On>
						</xsl:if>
	
						<xsl:call-template name="writeEarningDeductionEntry">
							<xsl:with-param name="changeRecord" select="."/>
							<xsl:with-param name="effectiveDate" select="$effectiveDate"/>
						</xsl:call-template>
					</adp:EarningsAndDeduction>
				</xsl:if>
			</xsl:for-each>	
		</adp:EarningsAndDeductions>

	</xsl:template>

	<xsl:template name="printEarningDeductionInMaster">
		<xsl:param name="changeRecord"/>
		<xsl:param name="effectiveDate"/>
		<xsl:param name="employeeStatus"/>

		
		<xsl:for-each select="$changeRecord/peci:Benefits_Earnings_and_Deductions">
			<xsl:if test="this:includeEarnDedInOutput(.) = true()">
				<adp:ChangeRecord>
					<xsl:call-template name="employeeIdentifier"/>
					
					<xsl:if test="xsd:boolean($ia.EffecitveDatingEnabled) = true()">
						<adp:Change_Effective_On>
							<xsl:value-of select="this:format-Date($effectiveDate)"/>
						</adp:Change_Effective_On>
					</xsl:if>
	
					<adp:Employee_Status>
						<xsl:value-of select="$employeeStatus"/>
					</adp:Employee_Status>
		
					<xsl:call-template name="createEmptyMaster">
						<xsl:with-param name="changeRecord" select="$changeRecord"/>
					</xsl:call-template>
		
					<xsl:call-template name="writeEarningDeductionEntry">
						<xsl:with-param name="changeRecord" select="."/>
						<xsl:with-param name="effectiveDate" select="$effectiveDate"/>
					</xsl:call-template>
					
					 <xsl:if test="xsd:boolean($is.IncludeDirectDepositInfo) = true() and xsd:boolean($ia.Split.PaymentElection.File) = false()">
						<xsl:call-template name="createEmptyPaymentElection"/>
					 </xsl:if>				
				</adp:ChangeRecord>
			</xsl:if>
		</xsl:for-each>	
	
		

	</xsl:template>

	<xsl:template name="writeEarningDeductionEntry">
		<xsl:param name="changeRecord"/>
		<xsl:param name="effectiveDate"/>
	
		


		<xsl:choose>
			<xsl:when test="peci:Earning_or_Deduction = 'E'">
			
				<xsl:variable name="isZeroAmount">
					<xsl:choose>
						<xsl:when test="exists(peci:Amount) = true()">
							<xsl:choose>
								<xsl:when test="number(peci:Amount) = 0">
									<xsl:value-of select="true()"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="false()"/>
								</xsl:otherwise>											
							</xsl:choose>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="false()"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="$isZeroAmount = true()">
						<adp:Additional_Earnings_Code>
							<xsl:value-of select="concat(peci:External_Payroll_Code,'~')"/>
						</adp:Additional_Earnings_Code>
						<adp:Additional_Earnings_Amount/>

					</xsl:when>
					<xsl:otherwise>
						<adp:Additional_Earnings_Code>
							<xsl:value-of select="peci:External_Payroll_Code"/>
						</adp:Additional_Earnings_Code>
						<adp:Additional_Earnings_Amount>
							<xsl:value-of select="peci:Amount"/>
						</adp:Additional_Earnings_Amount>									
						
					</xsl:otherwise>
				</xsl:choose>							

				<adp:Deduction_Code/>
				<adp:Deduction_Amount/>
				<adp:Deduction_Factor/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="isZeroAmount">
					<xsl:choose>
						<xsl:when test="exists(peci:Amount) = true()">
							<xsl:choose>
								<xsl:when test="number(peci:Amount) = 0">
									<xsl:value-of select="true()"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="false()"/>
								</xsl:otherwise>											
							</xsl:choose>
						</xsl:when>
						<xsl:when test="exists(peci:Percentage) = true()">
							<xsl:choose>
								<xsl:when test="number(peci:Percentage) = 0">
									<xsl:value-of select="true()"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="false()"/>
								</xsl:otherwise>											
							</xsl:choose>
						</xsl:when>										
						<xsl:otherwise>
							<xsl:value-of select="false()"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>							
				<adp:Additional_Earnings_Code/>
				<adp:Additional_Earnings_Amount/>
				<xsl:choose>
					<xsl:when test="$isZeroAmount = true()">
						<adp:Deduction_Code>
							<xsl:value-of select="concat(peci:External_Payroll_Code,'~')"/>
						</adp:Deduction_Code>
						<adp:Deduction_Amount/>
						<adp:Deduction_Factor/>
					</xsl:when>
					<xsl:otherwise>
						<adp:Deduction_Code>
							<xsl:value-of select="peci:External_Payroll_Code"/>
						</adp:Deduction_Code>									
						
						<xsl:choose>
							<xsl:when test="number(peci:Amount) > 0"> 
								<adp:Deduction_Amount>
									<xsl:value-of select="peci:Amount"/>
								</adp:Deduction_Amount>
								<Deduction_Factor/>							
							</xsl:when>
							<xsl:when test="number(peci:Percentage) > 0"> 
								<adp:Deduction_Amount/>
								<adp:Deduction_Factor>	
									<xsl:value-of select="peci:Percentage * 100"/>
								</adp:Deduction_Factor>								
							</xsl:when>
							<xsl:otherwise>
								<adp:Deduction_Amount>
									<xsl:value-of select="peci:Amount"/>
								</adp:Deduction_Amount>
								<Deduction_Factor/>	
							</xsl:otherwise>
						</xsl:choose>										
					</xsl:otherwise>
				</xsl:choose>									

				

										
			</xsl:otherwise>
		</xsl:choose>
	
	</xsl:template>	


	<xsl:template name="printPaymentElectionSeparately">
		<xsl:param name="changeRecord"/>
		<xsl:param name="effectiveDate"/>
		<xsl:param name="employeeStatus"/>

		<adp:PaymentElectionsRecord>	

			<!-- Delete all previous entry in ADP -->

			<!-- Delete Checking Entries -->
			<xsl:call-template name="DeletePaymentElectionAccounts">
				<xsl:with-param name="mapName" select="$CHECKING_MAP_NAME"/>
				<xsl:with-param name="effectiveDate" select="$effectiveDate"/>
				<xsl:with-param name="count" select="1"/>
				<xsl:with-param name="includeInMaster" select="false()"/>
				<xsl:with-param name="employeeStatus" select="$employeeStatus"/>
				<xsl:with-param name="changeRecord" select="$changeRecord"/>
			</xsl:call-template>
		  
		    
			<!-- Delete Savings Entries -->
			<xsl:call-template name="DeletePaymentElectionAccounts">
				<xsl:with-param name="mapName" select="$SAVINGS_MAP_NAME"/>
				<xsl:with-param name="effectiveDate" select="$effectiveDate"/>
				<xsl:with-param name="count" select="1"/>
				<xsl:with-param name="includeInMaster" select="false()"/>
				<xsl:with-param name="employeeStatus" select="$employeeStatus"/>
				<xsl:with-param name="changeRecord" select="$changeRecord"/>
			</xsl:call-template>

			<xsl:variable name="bankAccountCount" select="count($changeRecord/peci:Payment_Election[not(exists(@peci:isDeleted))])"/>	

			<!-- Process Checking Accounts-->
	
			<!-- process each Checking accounts -->
			<xsl:for-each select="/$changeRecord/peci:Payment_Election[peci:Account_Type = 'Checking' and not(exists(@peci:isDeleted))]">
				<xsl:sort select="peci:Order"/>
		
				<adp:Account>

					<xsl:call-template name="employeeIdentifier"/>

					<xsl:if test="xsd:boolean($ia.EffecitveDatingEnabled) = true()">
						<adp:Change_Effective_On>
							<xsl:value-of select="this:format-Date($effectiveDate)"/>
						</adp:Change_Effective_On>
					</xsl:if>

					<xsl:call-template name="writePaymentElectionEntry">
						<xsl:with-param name="changeRecord" select="."/>
						<xsl:with-param name="mapName" select="$CHECKING_MAP_NAME"/>
						<xsl:with-param name="effectiveDate" select="$effectiveDate"/>
						<xsl:with-param name="bankAccountCount" select="$bankAccountCount"/>
					</xsl:call-template>
				</adp:Account>
			</xsl:for-each>	


		<!-- Process Savings Accounts-->
	
			<!-- process each Savings accounts -->
			<xsl:for-each select="/$changeRecord/peci:Payment_Election[peci:Account_Type = 'Savings' and not(exists(@peci:isDeleted))]">
				<xsl:sort select="peci:Order"/>
		
				<adp:Account>

					<xsl:call-template name="employeeIdentifier"/>

					<xsl:if test="xsd:boolean($ia.EffecitveDatingEnabled) = true()">
						<adp:Change_Effective_On>
							<xsl:value-of select="this:format-Date($effectiveDate)"/>
						</adp:Change_Effective_On>
					</xsl:if>

					<xsl:call-template name="writePaymentElectionEntry">
						<xsl:with-param name="changeRecord" select="."/>
						<xsl:with-param name="mapName" select="$SAVINGS_MAP_NAME"/>
						<xsl:with-param name="effectiveDate" select="$effectiveDate"/>
						<xsl:with-param name="bankAccountCount" select="$bankAccountCount"/>
					</xsl:call-template>
				</adp:Account>
			</xsl:for-each>	
			
					<xsl:for-each select="/$changeRecord/peci:Payment_Election[peci:Account_Type = 'Savings' and not(exists(@peci:isDeleted))]">
				<xsl:sort select="peci:Order"/>
		
				<adp:Account>

					<xsl:call-template name="employeeIdentifier"/>

					<xsl:if test="xsd:boolean($ia.EffecitveDatingEnabled) = true()">
						<adp:Change_Effective_On>
							<xsl:value-of select="this:format-Date($effectiveDate)"/>
						</adp:Change_Effective_On>
					</xsl:if>

					<xsl:call-template name="writePaymentElectionEntry">
						<xsl:with-param name="changeRecord" select="."/>
						<xsl:with-param name="mapName" select="$SAVINGS_MAP_NAME"/>
						<xsl:with-param name="effectiveDate" select="$effectiveDate"/>
						<xsl:with-param name="bankAccountCount" select="$bankAccountCount"/>
					</xsl:call-template>
				</adp:Account>
			</xsl:for-each>	
		</adp:PaymentElectionsRecord>

	</xsl:template>

	<xsl:template name="printPaymentElectionInMaster">
		<xsl:param name="changeRecord"/>
		<xsl:param name="effectiveDate"/>
		<xsl:param name="employeeStatus"/>

			<!-- Delete all previous entry in ADP -->

			<!-- Delete Checking Entries -->
			<xsl:call-template name="DeletePaymentElectionAccounts">
				<xsl:with-param name="mapName" select="$CHECKING_MAP_NAME"/>
				<xsl:with-param name="effectiveDate" select="$effectiveDate"/>
				<xsl:with-param name="count" select="1"/>
				<xsl:with-param name="includeInMaster" select="true()"/>
				<xsl:with-param name="employeeStatus" select="$employeeStatus"/>
				<xsl:with-param name="changeRecord" select="$changeRecord"/>
			</xsl:call-template>

			<!-- Delete Saving Entries -->
			<xsl:call-template name="DeletePaymentElectionAccounts">
				<xsl:with-param name="mapName" select="$SAVINGS_MAP_NAME"/>
				<xsl:with-param name="effectiveDate" select="$effectiveDate"/>
				<xsl:with-param name="count" select="1"/>
				<xsl:with-param name="includeInMaster" select="true()"/>
				<xsl:with-param name="employeeStatus" select="$employeeStatus"/>
				<xsl:with-param name="changeRecord" select="$changeRecord"/>
			</xsl:call-template>

			<xsl:variable name="bankAccountCount" select="count($changeRecord/peci:Payment_Election[not(exists(@peci:isDeleted))])"/>	

			<!-- Process Checking Accounts-->
	
			<!-- process each Checking accounts -->
			<xsl:for-each select="/$changeRecord/peci:Payment_Election[peci:Account_Type = 'Checking' and not(exists(@peci:isDeleted))]">
				<xsl:sort select="peci:Order"/>
		
				<adp:ChangeRecord>
					<xsl:call-template name="employeeIdentifier"/>
					
					<xsl:if test="xsd:boolean($ia.EffecitveDatingEnabled) = true()">
						<adp:Change_Effective_On>
							<xsl:value-of select="this:format-Date($effectiveDate)"/>
						</adp:Change_Effective_On>
					</xsl:if>
	
					<adp:Employee_Status>
						<xsl:value-of select="$employeeStatus"/>
					</adp:Employee_Status>
		
					<xsl:call-template name="createEmptyMaster">
						<xsl:with-param name="changeRecord" select="$changeRecord"/>
					</xsl:call-template>
					
					<xsl:if test="xsd:boolean($is.IncludeBenefitInfo) = true() and xsd:boolean($ia.Split.Benefit.File) = false()">
					    <xsl:call-template name="createEmptyBenefit"/>
					</xsl:if> 					

					<xsl:call-template name="writePaymentElectionEntry">
						<xsl:with-param name="changeRecord" select="."/>
						<xsl:with-param name="mapName" select="$CHECKING_MAP_NAME"/>
						<xsl:with-param name="effectiveDate" select="$effectiveDate"/>
						<xsl:with-param name="bankAccountCount" select="$bankAccountCount"/>
					</xsl:call-template>
				</adp:ChangeRecord>
			</xsl:for-each>	


		<!-- Process Savings Accounts-->
	
			<!-- process each Savings accounts -->
			<xsl:for-each select="/$changeRecord/peci:Payment_Election[peci:Account_Type = 'Savings' and not(exists(@peci:isDeleted))]">
				<xsl:sort select="peci:Order"/>
		
				<adp:ChangeRecord>
					<xsl:call-template name="employeeIdentifier"/>
					
					<xsl:if test="xsd:boolean($ia.EffecitveDatingEnabled) = true()">
						<adp:Change_Effective_On>
							<xsl:value-of select="this:format-Date($effectiveDate)"/>
						</adp:Change_Effective_On>
					</xsl:if>
	
					<adp:Employee_Status>
						<xsl:value-of select="$employeeStatus"/>
					</adp:Employee_Status>
		
					<xsl:call-template name="createEmptyMaster">
						<xsl:with-param name="changeRecord" select="$changeRecord"/>
					</xsl:call-template>
					
					<xsl:if test="xsd:boolean($is.IncludeBenefitInfo) = true() and xsd:boolean($ia.Split.Benefit.File) = false()">
					    <xsl:call-template name="createEmptyBenefit"/>
					</xsl:if> 						

					<xsl:call-template name="writePaymentElectionEntry">
						<xsl:with-param name="changeRecord" select="."/>
						<xsl:with-param name="mapName" select="$SAVINGS_MAP_NAME"/>
						<xsl:with-param name="effectiveDate" select="$effectiveDate"/>
						<xsl:with-param name="bankAccountCount" select="$bankAccountCount"/>
					</xsl:call-template>
				</adp:ChangeRecord>
			</xsl:for-each>	

	</xsl:template>


	<xsl:template name="writePaymentElectionEntry">
		<xsl:param name="changeRecord"/>
		<xsl:param name="mapName"/>
		<xsl:param name="effectiveDate"/>
		<xsl:param name="bankAccountCount"/>

			<adp:Bank_Deposit_Position_Number columnHeading="Bank Deposit Position Number">
				<xsl:value-of select="peci:Order"/>
			</adp:Bank_Deposit_Position_Number>
			<adp:Bank_Deposit_Deduction_Code columnHeading="Bank Deposit Deduction Code">
				<xsl:value-of select="this:paymentElectionAttributeMap($mapName, peci:Order)"/>
			</adp:Bank_Deposit_Deduction_Code>
			<xsl:choose>
				<xsl:when test="peci:Distribution_Balance = '1' or $bankAccountCount = 1">
					<adp:Bank_Full_Deposit_Flag columnHeading="Bank Full Deposit Flag">
						<xsl:text>'Y'</xsl:text>
					</adp:Bank_Full_Deposit_Flag>
					<adp:Bank_Deposit_Deduction_Amount columnHeading="Bank Deposit Deduction Amount"/>
				</xsl:when>
				<xsl:otherwise>
					<adp:Bank_Full_Deposit_Flag columnHeading="Bank Full Deposit Flag">
						<xsl:text>'N'</xsl:text>
					</adp:Bank_Full_Deposit_Flag>
					<adp:Bank_Deposit_Deduction_Amount columnHeading="Bank Deposit Deduction Amount">
						<xsl:value-of select="(peci:Distribution_Amount)"/>
					</adp:Bank_Deposit_Deduction_Amount>
				</xsl:otherwise>
			</xsl:choose>
			<adp:Bank_Account_Name columnHeading="Bank Account Name">
			<xsl:value-of select="peci:Bank_Account_Name"/>
			</adp:Bank_Account_Name>
			
			<adp:Bank_Account_Number columnHeading="Bank Deposit Account Number">
				<xsl:value-of select="peci:Account_Number"/>
			</adp:Bank_Account_Number>
			
			<adp:Bank_Account_Type columnHeading="Bank Account Type">
				<xsl:value-of select="peci:Account_Type"/>
			</adp:Bank_Account_Type>
			
			<adp:Bank_Name columnHeading="Bank Name">
			<xsl:value-of select="peci:Bank_Name"/>
			</adp:Bank_Name>
			
			<adp:IBAN columnHeading="IBAN">
			<xsl:value-of select="peci:IBAN"/>
			</adp:IBAN>
			
			<adp:Bank_Deposit_Transit_ABA columnHeading="Sort Code / Routing /Bank ID">
				<xsl:value-of select="peci:Bank_ID"/>
			</adp:Bank_Deposit_Transit_ABA>
			
			<adp:Bank_Branch_Name columnHeading="Bank Branch Name">
			<xsl:value-of select="peci:Branch_Name"/>	
			</adp:Bank_Branch_Name>
			
			<adp:Branch_ID columnHeading="Branch ID">
			<xsl:value-of select="peci:Branch_ID"/>
			
			</adp:Branch_ID>
			
			<adp:Bank_Account_Country columnHeading="Bank Account Country">
				<xsl:value-of select="peci:Country"/>
			</adp:Bank_Account_Country>

	</xsl:template>

	<xsl:template name="DeletePaymentElectionAccounts">
		<xsl:param name="mapName"/>
		<xsl:param name="effectiveDate"/>
		<xsl:param name="count"/>
		<xsl:param name="includeInMaster"/>
		<xsl:param name="employeeStatus"/>
		<xsl:param name="changeRecord"/>

		<xsl:if test="this:paymentElectionAttributeMap($mapName, $count) ne '' and $count lt 6">
			<xsl:variable name="elementNameForEntry">
				<xsl:choose>
					<xsl:when test="$includeInMaster = true()">
						<xsl:text>adp:ChangeRecord</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>adp:Account</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
				
			<xsl:element name="{$elementNameForEntry}">
					<xsl:call-template name="employeeIdentifier"/>
					
					<xsl:if test="xsd:boolean($ia.EffecitveDatingEnabled) = true()">
						<adp:Change_Effective_On>
							<xsl:value-of select="this:format-Date($effectiveDate)"/>
						</adp:Change_Effective_On>
					</xsl:if>
	
					<xsl:if test="$includeInMaster = true()">
						<adp:Employee_Status>
							<xsl:value-of select="$employeeStatus"/>
						</adp:Employee_Status>
			
						
						<xsl:call-template name="createEmptyMaster">
							<xsl:with-param name="changeRecord" select="$changeRecord"/>
						</xsl:call-template>
						
						<xsl:if test="xsd:boolean($is.IncludeBenefitInfo) = true() and xsd:boolean($ia.Split.Benefit.File) = false()">
						    <xsl:call-template name="createEmptyBenefit"/>
						</xsl:if>  							
					</xsl:if>	
		
				<adp:Bank_Deposit_Position_Number columnHeading="Bank Deposit Position Number">
					<xsl:value-of select="$count"/>
				</adp:Bank_Deposit_Position_Number>
				<adp:Bank_Deposit_Deduction_Code adp:columnHeading="Bank Deposit Deduction Code">
					<xsl:value-of select="concat(this:paymentElectionAttributeMap($mapName, $count), '~')"/>
				</adp:Bank_Deposit_Deduction_Code>
				<adp:Bank_Full_Deposit_Flag columnHeading="Bank Full Deposit Flag"/>
				<adp:Bank_Deposit_Deduction_Amount columnHeading="Bank Deposit Deduction Amount"/>
				<adp:Bank_Account_Name columnHeading="Bank Account Name"/>
				<adp:Bank_Account_Number columnHeading="Bank Account Number"/>
				<adp:Bank_Account_Type columnHeading="Bank Account Type"/>
				<adp:Bank_Account_Name columnHeading="Bank Account Name"/>
				<adp:IBAN columnHeading="IBAN"/>
				<adp:Bank_Deposit_Transit_ABA columnHeading="Sort Code / Routing /Bank ID"/>
				<adp:Bank_Branch_Name columnHeading="Bank Branch Name"/>
				<adp:Branch_ID columnHeading="Branch ID"/>
				<adp:Bank_Account_Country columnHeading="Bank Account Country"/>
				
			</xsl:element>
			
			<xsl:call-template name="DeletePaymentElectionAccounts">
				<xsl:with-param name="mapName" select="$mapName"/>
				<xsl:with-param name="effectiveDate" select="$effectiveDate"/>
				<xsl:with-param name="count" select="$count + 1"/>
				<xsl:with-param name="includeInMaster" select="$includeInMaster"/>
				<xsl:with-param name="employeeStatus" select="$employeeStatus"/>
				<xsl:with-param name="changeRecord" select="$changeRecord"/>
			</xsl:call-template>
		</xsl:if>	
	</xsl:template>



	<xsl:function name="this:editHomePhoneNumber">
		<xsl:param name="homePhone"/>
		
		<xsl:variable name="editedPhone">
			<xsl:choose>
				<xsl:when test="exists($homePhone/peci:Area_Code) and exists($homePhone/peci:Phone_Number)">
					<xsl:value-of select="concat($homePhone/peci:Area_Code,$homePhone/peci:Phone_Number)"/>
				</xsl:when>
				<xsl:when test="exists($homePhone/peci:Phone_Number_With_Country_Code)">
					<xsl:value-of select="substring-after($homePhone/peci:Phone_Number_With_Country_Code, '+1')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$homePhone/peci:Phone_Number"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>	
	
		
		<xsl:value-of select="this:stripToNumericsOnly($editedPhone)"/>	
	</xsl:function>

	<xsl:function name="this:applyHomeDepartmentPadding">
		<xsl:param name="homeDepartment"/>

				<xsl:variable name="padding" select="'00000'"/>
				<xsl:variable name="returnLength" select="6"/>

				<xsl:variable name="value" select="concat($padding, $homeDepartment)"/>
				<xsl:variable name="start" select="number(string-length($value)) - $returnLength + 1"/>
				<xsl:value-of select="substring($value, $start, $returnLength)"/>	


	</xsl:function>	

	<xsl:function name="this:stripToNumericsOnly">
	    <xsl:param name="string" />
	    <xsl:variable name="NumbersSymbols" select="'0123456789'"/>
	    <xsl:variable name="phoneNumber"  select="translate($string, translate($string, $NumbersSymbols, ''), '')  "/>

		<xsl:choose>
			<xsl:when test="matches($phoneNumber,'[0-9]{7}') or matches($phoneNumber, '[0-9]{10}')">
				<xsl:value-of select="$phoneNumber"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="''"/>
			</xsl:otherwise>
		</xsl:choose>
    
	</xsl:function> 	

	<xsl:function name="this:format-Date">
		<xsl:param name="input-date"/>
		
		<xsl:variable name="formatted-date">
		<xsl:choose>
			<xsl:when test="string-length($input-date) ne 0">
				<xsl:value-of select="string(format-date(xsd:date($input-date),'[Y0001]/[M01]/[D01]'))"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$input-date"/>
			</xsl:otherwise>
		</xsl:choose>
		</xsl:variable>

		<xsl:value-of select="$formatted-date"/>
	</xsl:function>

	<xsl:function name="this:formatSSN">
		<xsl:param name="ssn"/>
		<xsl:value-of select="if (string-length($ssn) = 9) then concat(substring($ssn, 1,3), '-', substring($ssn, 4,2), '-', substring($ssn, 6,4)) else ''"/>
	</xsl:function>

	<xsl:function name="this:isCheckFieldChangedOnly">
		<xsl:param name="fieldNode"/>
	
		<xsl:choose>
			<xsl:when test="exists($fieldNode/@peci:PriorValue) = true() or exists($fieldNode/@peci:isAdded) = true()">
				<xsl:value-of select="true()"/>			
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="false()"/>
			</xsl:otherwise>		
		</xsl:choose>
	</xsl:function>	

	<xsl:function name="this:isSectionChanged">
		<xsl:param name="fieldNode"/>
	
		<xsl:choose>
			<xsl:when test="exists($fieldNode/@peci:isUpdated) = true() or exists($fieldNode/@peci:isAdded) = true()">
				<xsl:value-of select="true()"/>			
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="false()"/>
			</xsl:otherwise>		
		</xsl:choose>
	</xsl:function>	
	
	<xsl:function name="this:includeChangesOnly">
		<xsl:param name="element-name" />
		<xsl:param name="elementNode" />				
	
		
		<xsl:element name="{$element-name}">
			<xsl:choose>
				<xsl:when test="this:isFieldChanged($elementNode) = true()">
					<xsl:value-of select="$elementNode/text()" />
				</xsl:when>
				<xsl:otherwise/>
			</xsl:choose>
		</xsl:element>	

	</xsl:function>		

	<xsl:function name="this:isFieldChanged">
		<xsl:param name="fieldNode"/>
	


		<xsl:choose>
			<!--
			<xsl:when test="$isNewHire = true()">
				<xsl:value-of select="true()"/>			
			</xsl:when>
			  -->
			<xsl:when test="exists($fieldNode/@peci:PriorValue) = true() or exists($fieldNode/@peci:isAdded) = true()">
				<xsl:value-of select="true()"/>			
			</xsl:when>			
			<xsl:otherwise>
				<xsl:value-of select="false()"/>
			</xsl:otherwise>		
		</xsl:choose>
	</xsl:function>
	
	<xsl:function name="this:isPositionFieldChanged">
		<xsl:param name="currentPosition"/>
		<xsl:param name="previousPosition"/>
		<xsl:param name="fieldName"/>

		<xsl:choose>
			<!-- Check if position has changed -->
			<xsl:when test="$currentPosition/peci:Operation = 'ADD' and $previousPosition/peci:Operation = 'REMOVE'">
				<xsl:choose>
					<xsl:when test="$currentPosition/*[local-name() = $fieldName] != $previousPosition/*[local-name() = $fieldName]">
						<xsl:value-of select="true()"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="false()"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="this:isFieldChanged($currentPosition/*[local-name() = $fieldName]) = true()">
				<xsl:value-of select="true()"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="false()"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>	


	<xsl:function name="this:setAddressLine">
		<xsl:param name="inputValue"/>
		<xsl:variable name="workingValue" select="substring($inputValue, 1, $ADDRESS_LENGTH + 1)"/>
		<xsl:value-of select="reverse(remove(reverse(tokenize($workingValue, '\s+')), 1))"/>
	</xsl:function>

	<xsl:function name="this:setAddress1">
		<xsl:param name="address1"/>
		<xsl:param name="address2"/>
		<xsl:choose>
			<xsl:when test="not($address1)">
				<xsl:value-of select="'~'"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="string-length($address1) gt $ADDRESS_LENGTH">
						<xsl:value-of select="this:setAddressLine($address1)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$address1"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<xsl:function name="this:setAddress2">
		<xsl:param name="address1"/>
		<xsl:param name="address2"/>
		<xsl:choose>
			<xsl:when test="(not($address1) or $ADDRESS_LENGTH ge string-length($address1)) and not($address2)">
				<xsl:value-of select="'~'"/>
			</xsl:when>
			<xsl:when test="(not($address1) or $ADDRESS_LENGTH ge string-length($address1)) and string-length($address2) = 0">
				<xsl:value-of select="'~'"/>
			</xsl:when>			
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="$ADDRESS_LENGTH ge string-length($address1)">
						<xsl:value-of select="substring($address2, 1, $ADDRESS_LENGTH)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:variable name="addressLine1Length" select="string-length(this:setAddressLine($address1))+1"/>
						<xsl:variable name="combinedAddressLines" select="concat($address1, ' ', $address2)"/>
						<xsl:value-of select="substring($combinedAddressLines, $addressLine1Length, $ADDRESS_LENGTH)"/>
					</xsl:otherwise>
				</xsl:choose>		
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>	

	<xsl:function name="this:employment-status">
		<xsl:param name="changeRecord"/>
		<!-- Possible values: 1) A - Active 2) T - Terminated 3) L - Leave of absence 4) D - Deceased -->
		
		<!-- TODO: Need to enhance DECEASED logic by combining employeeStatus and termination reason -->
		
		<xsl:variable name="eventCode" select="upper-case($changeRecord/peci:Derived_Event_Code) "/>
		<xsl:choose>
			<xsl:when test="$eventCode = 'HIR' or $eventCode = 'PCI'">
				<xsl:value-of select="$ACTIVE"/>
			</xsl:when>	
				<xsl:when test="$eventCode = 'RFL'">
				<xsl:value-of select="$ACTIVE"/>
			</xsl:when>				
			<!--<xsl:when test="$eventCode = 'LOA' or $eventCode = 'LOA-C'">
				<xsl:value-of select="$LOA"/>
			</xsl:when>
			<xsl:when test="exists($changeRecord/peci:Leave_of_Absence) and not(exists($changeRecord/peci:Leave_of_Absence/peci:Leave_End_Date))">
				<xsl:value-of select="$LOA"/>
			</xsl:when>-->
			<xsl:when test="$eventCode = 'TERM' or $eventCode = 'PCO' or $eventCode='PGO'">
				<xsl:value-of select="$TERMINATED"/>
			</xsl:when>
			<xsl:when test="exists($changeRecord/peci:Worker_Status/peci:Termination_Date)  and $changeRecord/peci:Worker_Status/peci:Status ne 'Active'">
				<xsl:value-of select="$TERMINATED"/>
			</xsl:when>
			<xsl:otherwise/>
		</xsl:choose>
	</xsl:function>

	<xsl:function name="this:checkIfNewHire">
		<xsl:param name="payeeNode"/>
		
		<xsl:choose>
			
			<xsl:when test="exists($payeeNode[peci:Derived_Event_Code = 'HIR' or peci:Derived_Event_Code = 'PCI']) = true()">
				<xsl:value-of select="true()"/>
			</xsl:when>			
				
			<xsl:otherwise>
				<xsl:value-of select="false()"/>
			</xsl:otherwise>
		</xsl:choose>


	</xsl:function>	
	
	<xsl:function name="this:checkIfRFL">
		<xsl:param name="payeeNode"/>
		
		<xsl:choose>
			<xsl:when test="exists($payeeNode[peci:Derived_Event_Code = 'RFL']) = true()">
				<xsl:value-of select="true()"/>
			</xsl:when>
						
			<xsl:otherwise>
				<xsl:value-of select="false()"/>
			</xsl:otherwise>
		</xsl:choose>


	</xsl:function>		

	<xsl:function name="this:ApplyMap">
		<xsl:param name="mapName"/>
		<xsl:param name="sortid"/>

	</xsl:function>

	<xsl:function name="this:paymentElectionAttributeMap">
		<xsl:param name="mapName"/>
		<xsl:param name="order"/>
		

		<xsl:value-of select="$recordNode/peci:PECI_Config/peci:Custom_Mapping/peci:Custom_Map[peci:Map_Name = $mapName]/peci:Field[number(peci:Workday_Value) = $order]/peci:ADP_Value"/>

	</xsl:function>

	<xsl:function name="this:includeEarnDedInOutput">
		<xsl:param name="earndedRecord"/>
		
		<xsl:choose>
			<!-- Handle Deduction Records -->
			<xsl:when test="$earndedRecord/peci:Earning_or_Deduction = 'D'">
				<xsl:choose>
					<xsl:when test="number($earndedRecord/peci:Amount) > 0">
						<xsl:value-of select="true()"/>
					</xsl:when>
					<xsl:when test="number($earndedRecord/peci:Amount) = 0 and exists($earndedRecord/peci:Amount/@peci:priorValue)">
						<xsl:value-of select="true()"/>
					</xsl:when>
					<xsl:when test="number($earndedRecord/peci:Percentage) > 0">
						<xsl:value-of select="true()"/>
					</xsl:when>
					<xsl:when test="number($earndedRecord/peci:Percentage) = 0 and exists($earndedRecord/peci:Percentage/@peci:priorValue)">
						<xsl:value-of select="true()"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="false()"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<!-- Handle Earning Records -->
			<xsl:when test="$earndedRecord/peci:Earning_or_Deduction = 'E'">
				<xsl:choose>
					<xsl:when test="number($earndedRecord/peci:Amount) > 0">
						<xsl:value-of select="true()"/>
					</xsl:when>
					<xsl:when test="number($earndedRecord/peci:Amount) = 0 and exists($earndedRecord/peci:Amount/@peci:priorValue)">
						<xsl:value-of select="true()"/>
					</xsl:when>
					<xsl:when test="number($earndedRecord/peci:Percentage) > 0">
						<xsl:value-of select="true()"/>
					</xsl:when>
					<xsl:when test="number($earndedRecord/peci:Percentage) = 0 and exists($earndedRecord/peci:Percentage/@peci:priorValue)">
						<xsl:value-of select="true()"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="false()"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="false()"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>	

</xsl:stylesheet>