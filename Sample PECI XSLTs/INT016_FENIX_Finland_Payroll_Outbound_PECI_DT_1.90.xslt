<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:peci="urn:com.workday/peci"
	xmlns:xtt="urn:com.workday/xtt" xmlns:etv="urn:com.workday/etv"
	xmlns:ptdf="urn:com.workday/peci/tdf" xmlns:func="http://func.com"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	exclude-result-prefixes="xs" version="2.0">

	<!-- Change Log: Nov 13 2018 - Update, to handle non numeric postal code 
	     Using version xsl ver 1.86 as baseline Jan 15 2018 - New logic for calculated 
		 salary amount for staff and management -->

	<!-- ==== Value of Integration Attribute Pay Group ==== -->

	<!-- <xsl:param name="attr_Pay_Group"/> -->

	<!-- Additional template to handle multi paygroup selection, in use only 
		for studio integration version, autum 2018 -->
	<xsl:template match="peci:Workers_Effective_Stack_Merged">
		<File xtt:align="left">
			<xsl:apply-templates select="peci:Workers_Effective_Stack" />
		</File>
	</xsl:template>

	<xsl:template match="peci:Workers_Effective_Stack">
		<File xtt:align="left">
			<xsl:apply-templates select="peci:Worker" />
		</File>
	</xsl:template>

	<xsl:template match="peci:Worker">
		<xsl:apply-templates select="peci:Effective_Change">
			<xsl:sort select="substring(peci:Effective_Moment, 0, 11)"
				order="ascending" />
		</xsl:apply-templates>
	</xsl:template>

	<xsl:template match="peci:Effective_Change">

		<!-- ==== Employee_ID Variable ==== -->
		<xsl:variable name="Employee_ID">
			<xsl:value-of select="../peci:Worker_Summary/peci:Employee_ID" />
		</xsl:variable>
		<!-- ==== Employee_WID Variable ==== -->
		<xsl:variable name="Employee_WID">
			<xsl:value-of select="../peci:Worker_Summary/peci:WID" />
		</xsl:variable>

		<!-- ==== Staffing_Event Variable ==== -->
		<xsl:variable name="Staffing_Event">
			<xsl:choose>
				<!-- ==== New Hires ==== -->
				<xsl:when test="peci:Derived_Event_Code = 'HIR'">
					<xsl:value-of select="'G1'" />
				</xsl:when>
				<!-- ==== Terminated Workers ==== -->
				<xsl:when test="peci:Derived_Event_Code = ('TERM', 'TERM-C')">
					<xsl:value-of select="'G3'" />
				</xsl:when>
				<!-- ==== Rescinded Terminations ==== -->
				<xsl:when test="peci:Derived_Event_Code = 'TERM-R'">
					<xsl:value-of select="'G4'" />
				</xsl:when>
				<!-- ==== Organizational Changes ==== -->
				<xsl:when test="peci:Derived_Event_Code = 'ORG'">
					<xsl:choose>
						<xsl:when test="peci:Worker_Status/peci:Status = 'Active'">
							<xsl:value-of select="'G2'" />
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="'G5'" />
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<!-- ==== Other Events ==== -->
				<xsl:otherwise>
					<xsl:value-of select="''" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<!-- ==== Effective Moment Variable ==== -->
		<xsl:variable name="EffectiveMoment" select="peci:Effective_Moment" />

		<!-- ==== Sorted Sequence Variable ==== -->
		<xsl:variable name="sorted_sequence">
			<peci:Worker xmlns:peci="urn:com.workday/peci">
				<xsl:copy-of select="../peci:Worker_Summary" />
				<xsl:for-each
					select="../peci:Effective_Change[xs:date(substring(peci:Effective_Moment, 0, 11)) &lt;= xs:date(substring($EffectiveMoment, 0, 11))]">
					<xsl:sort select="peci:Effective_Moment" order="descending" />
					<xsl:copy-of select="." />
				</xsl:for-each>
			</peci:Worker>
		</xsl:variable>

		<!-- ==== New Hire Variable ==== -->
		<xsl:variable name="new_hire" as="xs:boolean">
			<xsl:choose>
				<xsl:when
					test="peci:Derived_Event_Code = 'HIR' or peci:Derived_Event_Code = 'PCI' or peci:Derived_Event_Code = 'PGI'">
					<xsl:value-of select="true()" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="false()" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<Record>

			<xsl:choose>

				<!-- 25.06.2019 - Moved to be a warning ==== FOR PAY GROUP TRANSFERS 
					NOTIFY THE LOCAL TEAM - DO NOT PROCESS RECORD IN PAYROLL FILE ==== <xsl:when 
					test="../peci:Effective_Change/peci:Derived_Event_Code = ('PGI','PGO')"> 
					<xsl:variable name="Message" select="'Worker has had a Pay Group Transfer. 
					Manual updates required.'" /> <element etv:severity="error" etv:targetWID="{$Employee_WID}" 
					etv:message="{$Message}" xtt:omit="true" /> </xsl:when> -->
				<!-- ==== FOR INTERNATIONAL TRANSFERS NOTIFY THE LOCAL TEAM - DO NOT 
					PROCESS RECORD IN PAYROLL FILE ==== -->
				<xsl:when
					test="../peci:Effective_Change/peci:Derived_Event_Code = ('PCI','PCO')">
					<xsl:variable name="Message"
						select="'Worker has had a Pay Group Transfer out of Finland. Manual updates required.'" />
					<element etv:severity="error" etv:targetWID="{$Employee_WID}"
						etv:message="{$Message}" xtt:omit="true" />
				</xsl:when>
				<!-- ==== FOR RESCINDED HIRES NOTIFY THE LOCAL TEAM - DO NOT PROCESS 
					RECORD IN PAYROLL FILE ==== -->
				<xsl:when
					test="../peci:Effective_Change/peci:Derived_Event_Code = 'HIR-R'">
					<xsl:variable name="Message"
						select="'Worker has had a rescinded hire event. Manual updates required.'" />
					<element etv:severity="error" etv:targetWID="{$Employee_WID}"
						etv:message="{$Message}" xtt:omit="true" />
				</xsl:when>

				<!-- ==== ONLY PROCESS WORKERS WITH VALID FENIX STAFFING EVENT ==== -->
				<xsl:otherwise>

					<!-- ==== FOR PAY GROUP TRANSFERS NOTIFY THE LOCAL TEAM - PROCESS RECORD 
						IN PAYROLL FILE ==== -->
					<xsl:if
						test="../peci:Effective_Change/peci:Derived_Event_Code = ('PGI','PGO')">
						<xsl:variable name="Message"
							select="'Worker has had a Pay Group Transfer. Manual updates required.'" />
						<element etv:severity="error" etv:targetWID="{$Employee_WID}"
							etv:message="{$Message}" xtt:omit="true" />
					</xsl:if>
					<!-- ==== FOR RETURN FROM LEAVE NOTIFY THE LOCAL TEAM - PROCESS RECORD 
						IN PAYROLL FILE ==== -->
					<xsl:if test="peci:Derived_Event_Code = 'RFL'">
						<xsl:variable name="Message"
							select="'Worker has had a return from leave event. Manual updates required.'" />
						<element etv:severity="error" etv:targetWID="{$Employee_WID}"
							etv:message="{$Message}" xtt:omit="true" />
					</xsl:if>
					<!-- ==== FOR LEAVE OF ASENCE NOTIFY THE LOCAL TEAM - PROCESS RECORD 
						IN PAYROLL FILE ==== -->
					<xsl:if test="peci:Derived_Event_Code = 'LOA'">
						<xsl:variable name="Message"
							select="'Worker has had a leave event. Manual updates required.'" />
						<element etv:severity="error" etv:targetWID="{$Employee_WID}"
							etv:message="{$Message}" xtt:omit="true" />
					</xsl:if>
					<!-- ==== FOR RETURN FROM LEAVE RESCINDS NOTIFY THE LOCAL TEAM - PROCESS 
						RECORD IN PAYROLL FILE ==== -->
					<xsl:if test="peci:Derived_Event_Code = 'RFL-R'">
						<xsl:variable name="Message"
							select="'Worker has had a rescinded return from leave event. Manual updates required.'" />
						<element etv:severity="error" etv:targetWID="{$Employee_WID}"
							etv:message="{$Message}" xtt:omit="true" />
					</xsl:if>

					<!-- ==== Pay_Group Variable ==== -->
					<!-- <xsl:variable name="Pay_Group" select="$attr_Pay_Group"/> -->
					<!-- Pay Group value is available as part of the PECI output instead -->
					<xsl:variable name="Pay_Group"
						select="substring(peci:Additional_Information/ptdf:TYEL_Value, 5,3)" />

					<!-- ==== TYEL Map Variable ==== -->
					<xsl:variable name="TYEL_Map_Value">
						<xsl:choose>
							<xsl:when test="peci:Additional_Information/ptdf:TYEL_Value = '__'">
								<xsl:value-of
									select="peci:Additional_Information/ptdf:TYEL_Value/@peci:priorValue" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="peci:Additional_Information/ptdf:TYEL_Value" />
							</xsl:otherwise>
						</xsl:choose>

					</xsl:variable>

					<!-- ==== TYEL Mapped Variable ==== -->
					<xsl:variable name="TYEL_Mapped_Value"
						select="$TYELMap/TYEL[@key = $TYEL_Map_Value]/@value" />

					<!-- ==== TYEL_Code Variable ==== -->
					<xsl:variable name="TYEL_Code">
						<xsl:if test="$TYEL_Mapped_Value">
							<xsl:value-of select="substring($TYEL_Mapped_Value, 1, 3)" />
						</xsl:if>
					</xsl:variable>

					<!-- ==== TYEL_Dept Variable ==== -->
					<xsl:variable name="TYEL_Dept">
						<xsl:if test="$TYEL_Mapped_Value">
							<xsl:value-of select="substring($TYEL_Mapped_Value, 5, 2)" />
						</xsl:if>
					</xsl:variable>

					<!-- ==== City_Number Variable ==== -->
					<xsl:variable name="City_Number">
						<xsl:if test="$TYEL_Mapped_Value">
							<xsl:value-of select="substring($TYEL_Mapped_Value, 8, 8)" />
						</xsl:if>
					</xsl:variable>

					<!-- ==== Collective Agreement Variables ==== -->
					<xsl:variable name="PayScaleType">
						<xsl:choose>
							<xsl:when
								test="exists($sorted_sequence/peci:Worker/peci:Effective_Change[1]/peci:Collective_Agreement/peci:Collective_Agreement_Factor[(peci:Factor = 'PROFESSIONAL_CATEGORY' and peci:Option = ('3'))])">
								<xsl:value-of select="'OP'" />
							</xsl:when>
							<xsl:otherwise />
						</xsl:choose>
					</xsl:variable>

					<!-- ==== Pay Scale Level Variables ==== -->
					<xsl:variable name="PayScaleLevel">
						<xsl:choose>
							<xsl:when
								test="$new_hire = true() and $sorted_sequence/peci:Worker/peci:Effective_Change[1]/peci:Collective_Agreement/peci:Collective_Agreement_Factor[(peci:Factor = 'PROFESSIONAL_CATEGORY' and peci:Option = ('01', '02', '03', '04', '05', '06', '07', '08', '09', '10'))]/peci:Option">
								<xsl:value-of
									select="$sorted_sequence/peci:Worker/peci:Effective_Change[1]/peci:Collective_Agreement/peci:Collective_Agreement_Factor[(peci:Factor = 'PROFESSIONAL_CATEGORY' and peci:Option = ('01', '02', '03', '04', '05', '06', '07', '08', '09', '10'))]/peci:Option" />
							</xsl:when>
							<xsl:when
								test="peci:elementChanged($sorted_sequence/peci:Worker/peci:Effective_Change[1]/peci:Collective_Agreement/peci:Collective_Agreement_Factor[(peci:Factor = 'PROFESSIONAL_CATEGORY' and peci:Option = ('01', '02', '03', '04', '05', '06', '07', '08', '09', '10'))]/peci:Option) = 'CH1'">
								<xsl:value-of
									select="$sorted_sequence/peci:Worker/peci:Effective_Change[1]/peci:Collective_Agreement/peci:Collective_Agreement_Factor[(peci:Factor = 'PROFESSIONAL_CATEGORY' and peci:Option = ('01', '02', '03', '04', '05', '06', '07', '08', '09', '10'))]/peci:Option" />
							</xsl:when>
							<xsl:when
								test="peci:elementChanged($sorted_sequence/peci:Worker/peci:Effective_Change[1]/peci:Collective_Agreement/peci:Collective_Agreement_Factor[(peci:Factor = 'PROFESSIONAL_CATEGORY' and peci:Option = ('01', '02', '03', '04', '05', '06', '07', '08', '09', '10'))]/peci:Option) = ('CHA', 'CHP')">
								<xsl:value-of
									select="
                                        peci:setNewPath($sorted_sequence/peci:Worker/peci:Effective_Change[1]/peci:Collective_Agreement/peci:Collective_Agreement_Factor[(peci:Factor = 'PROFESSIONAL_CATEGORY' and peci:Option = ('01', '02', '03', '04', '05', '06', '07', '08', '09', '10'))]/peci:Option,
                                        peci:elementChanged($sorted_sequence/peci:Worker/peci:Effective_Change[1]/peci:Collective_Agreement/peci:Collective_Agreement_Factor[(peci:Factor = 'PROFESSIONAL_CATEGORY' and peci:Option = ('01', '02', '03', '04', '05', '06', '07', '08', '09', '10'))]/peci:Option))" />
							</xsl:when>
							<xsl:otherwise />
						</xsl:choose>
					</xsl:variable>

					<!-- ==== Comp Change Reason Variable ==== -->
					<xsl:variable name="CompChangeReason">
						<xsl:choose>
							<xsl:when
								test="../peci:Effective_Change/peci:Compensation[last()]/peci:Compensation_Change_Reason[last()] = 'unmapped'">
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of
									select="../peci:Effective_Change/peci:Compensation[last()]/peci:Compensation_Change_Reason[last()]" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>

					<!-- ==== Effective Date Variable ==== -->
					<xsl:variable name="Effective_Date">
						<xsl:value-of select="xs:date(substring(peci:Effective_Moment, 0, 11))" />
					</xsl:variable>

					<!-- ==== Salary Type Variable ==== -->
					<xsl:variable name="PayRateType">
						<xsl:value-of
							select="peci:Additional_Information/ptdf:Pay_Rate_Type/ptdf:Pay_Rate_Type_ID" />
					</xsl:variable>

					<!-- ==== INFOTYPE 0000 ==== -->
					<!-- ==== Termination Date Variable ==== -->
					<xsl:variable name="TerminationDate">
						<xsl:choose>
							<xsl:when test="peci:Worker_Status/peci:Termination_Date">
								<xsl:value-of
									select="xs:date(substring(peci:Worker_Status/peci:Termination_Date, 0, 11))" />
							</xsl:when>
							<xsl:otherwise />
						</xsl:choose>
					</xsl:variable>
					<!-- ==== Hire Date Variable ==== -->
					<xsl:variable name="HireDate">
						<xsl:choose>
							<xsl:when test="peci:Worker_Status/peci:Hire_Date">
								<xsl:value-of
									select="xs:date(substring(peci:Worker_Status/peci:Hire_Date, 0, 11))" />
							</xsl:when>
							<xsl:otherwise />
						</xsl:choose>
					</xsl:variable>
					<!-- ==== Original Date Variable ==== -->
					<xsl:variable name="OriginalHireDate">
						<xsl:choose>
							<xsl:when test="peci:Worker_Status/peci:Original_Hire_Date">
								<xsl:value-of
									select="xs:date(substring(peci:Worker_Status/peci:Original_Hire_Date, 0, 11))" />
							</xsl:when>
							<xsl:otherwise />
						</xsl:choose>
					</xsl:variable>
					<!-- ==== Call template IT0000 for only those workers with a valid Worker 
						Status ==== -->
					<xsl:if test="$Staffing_Event = ('G1', 'G2', 'G3', 'G4', 'G5')">
						<xsl:call-template name="IT0000">
							<xsl:with-param name="Employee_ID" select="$Employee_ID" />
							<xsl:with-param name="Staffing_Event" select="$Staffing_Event" />
							<xsl:with-param name="TerminationDate" select="$TerminationDate" />
							<xsl:with-param name="HireDate" select="$HireDate" />
							<xsl:with-param name="OriginalHireDate" select="$OriginalHireDate" />
						</xsl:call-template>
					</xsl:if>
					<!-- ==== END OF INFOTYPE 0000 ==== -->

					<!-- ==== INFOTYPE 0001 ==== -->
					<!-- ==== Company Changed Variable ==== -->
					<xsl:variable name="CompanyChanged" as="xs:boolean">
						<xsl:choose>
							<xsl:when
								test="peci:elementChanged(peci:Position/peci:Organization[peci:Organization_Type = 'Company']/peci:Organization_Code) = ('CH1', 'CHA', 'CHP')">
								<xsl:value-of select="true()" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="false()" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- ==== Company Variable ==== -->
					<xsl:variable name="Company">
						<xsl:value-of
							select="peci:Position/peci:Organization[peci:Organization_Type = 'Company']/peci:Organization_Code" />
					</xsl:variable>
					<!-- ==== Terminated Changed Variable ==== -->
					<xsl:variable name="TerminatedChanged" as="xs:boolean">
						<xsl:choose>
							<xsl:when
								test="peci:elementChanged(peci:Worker_Status/peci:Terminated) = ('CH1', 'CHA', 'CHP')">
								<xsl:value-of select="true()" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="false()" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- ==== Terminated Variable ==== -->
					<xsl:variable name="Terminated">
						<xsl:value-of select="peci:Worker_Status/peci:Terminated" />
					</xsl:variable>
					<!-- ==== Professional Category Changed Variable ==== -->
					<xsl:variable name="ProfessionalCategoryChanged" as="xs:boolean">
						<xsl:choose>
							<xsl:when
								test="peci:elementChanged($sorted_sequence/peci:Worker/peci:Effective_Change[1]/peci:Collective_Agreement[not(@peci:isDeleted = '1')]/peci:Collective_Agreement_Factor[peci:Factor = 'PROFESSIONAL_CATEGORY' and peci:Option = ('1', '2', '3', '4', '5')]/peci:Option) = ('CH1', 'CHA', 'CHP')">
								<xsl:value-of select="true()" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="false()" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- ==== Professional Category Variable ==== -->
					<xsl:variable name="ProfessionalCategory">
						<xsl:value-of
							select="$sorted_sequence/peci:Worker/peci:Effective_Change[1]/peci:Additional_Information/ptdf:Collective_Agreement_Professional_Category" />
					</xsl:variable>
					<!-- ==== Cost Center Changed Variable ==== -->
					<xsl:variable name="CostCenterChanged" as="xs:boolean">
						<xsl:choose>
							<xsl:when
								test="peci:elementChanged(peci:Position/peci:Organization[not(@peci:isDeleted = '1') and peci:Organization_Type = 'Cost_Center']/peci:Organization_Code) = ('CH1', 'CHA', 'CHP')">
								<xsl:value-of select="true()" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="false()" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- ==== Cost Center Variable ==== -->
					<xsl:variable name="CostCenter">
						<xsl:value-of
							select="peci:Position[not(exists(peci:Position_End_Date/@peci:isAdded))]/peci:Organization[not(@peci:isDeleted = '1') and peci:Organization_Type = 'Cost_Center']/peci:Organization_Code" />
					</xsl:variable>
					<!-- ==== Business Title Changed Variable ==== -->
					<xsl:variable name="BusinessTitleChanged" as="xs:boolean">
						<xsl:choose>
							<xsl:when
								test="peci:elementChanged(peci:Position/peci:Business_Title) = ('CH1', 'CHA', 'CHP')">
								<xsl:value-of select="true()" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="false()" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- ==== Business Title Variable ==== -->
					<xsl:variable name="BusinessTitle">
						<xsl:value-of
							select="translate(peci:Position[not(exists(peci:Position_End_Date/@peci:isAdded))]/peci:Business_Title,'-',' ')" />
					</xsl:variable>
					<!-- ==== Worker Type Changed Variable ==== -->
					<xsl:variable name="WorkerTypeChanged" as="xs:boolean">
						<xsl:choose>
							<xsl:when
								test="peci:elementChanged(peci:Position/peci:Worker_Type) = ('CH1', 'CHA', 'CHP')">
								<xsl:value-of select="true()" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="false()" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- ==== Worker Type Variable ==== -->
					<xsl:variable name="WorkerType">
						<xsl:value-of
							select="peci:Position[not(exists(peci:Position_End_Date/@peci:isAdded))]/peci:Worker_Type" />
					</xsl:variable>
					<!-- ==== Job Category Changed Variable ==== -->
					<xsl:variable name="JobCategoryChanged" as="xs:boolean">
						<xsl:choose>
							<xsl:when
								test="peci:elementChanged(peci:Position/peci:Job_Category) = ('CH1', 'CHA', 'CHP')">
								<xsl:value-of select="true()" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="false()" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- ==== Job Category Variable ==== -->
					<xsl:variable name="JobCategory">
						<xsl:value-of
							select="peci:Position[not(exists(peci:Position_End_Date/@peci:isAdded))]/peci:Job_Category" />
					</xsl:variable>
					<!-- ==== Job Family Changed Variable ==== -->
					<xsl:variable name="JobFamilyChanged" as="xs:boolean">
						<xsl:choose>
							<xsl:when
								test="peci:elementChanged(peci:Position/peci:Job_Family) = ('CH1', 'CHA', 'CHP')">
								<xsl:value-of select="true()" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="false()" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- ==== Job Family Variable ==== -->
					<xsl:variable name="JobFamily">
						<xsl:value-of
							select="peci:Position[not(exists(peci:Position_End_Date/@peci:isAdded))]/peci:Job_Family" />
					</xsl:variable>
					<!-- ==== Workers Position or Status has changed Variable ==== -->
					<xsl:variable name="trueINT0001PositionStatusChange"
						as="xs:boolean">
						<xsl:choose>
							<!-- ==== Workers position has been added ==== -->
							<xsl:when test="exists(peci:Position[@peci:isAdded = '1'])">
								<xsl:value-of select="true()" />
							</xsl:when>
							<!-- ==== Workers status has been added ==== -->
							<xsl:when test="exists(peci:Status[@peci:isAdded = '1'])">
								<xsl:value-of select="true()" />
							</xsl:when>
							<!-- ==== Workers company has been added or updated ==== -->
							<xsl:when
								test="exists(peci:Position/peci:Organization[peci:Organization_Type = 'Company' and @peci:isAdded = '1']) or (exists(peci:Position/peci:Organization[peci:Organization_Type = 'Company' and @peci:isUpdated = '1']) and exists(peci:Position/peci:Organization[peci:Organization_Type = 'Company']/peci:Organization_Code/@peci:priorValue))">
								<xsl:value-of select="true()" />
							</xsl:when>
							<!-- ==== Worker has been rehired ==== -->
							<xsl:when
								test="exists(peci:Worker_Status[@peci:Updated = '1']) and exists(peci:Worker_Status/peci:Terminated/@peci:priorValue)">
								<xsl:value-of select="true()" />
							</xsl:when>
							<!-- ==== Workers cost center has been added or updated ==== -->
							<xsl:when
								test="exists(peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center' and @peci:isAdded = '1']) or (exists(peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center' and @peci:isUpdated = '1']) and exists(peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center']/peci:Organization_Code/@peci:priorValue))">
								<xsl:value-of select="true()" />
							</xsl:when>
							<!-- ==== Workers Business Title has been updated ==== -->
							<xsl:when
								test="exists(peci:Position[@peci:Updated = '1']) and exists(peci:Position/peci:Business_Title/@peci:priorValue)">
								<xsl:value-of select="true()" />
							</xsl:when>
							<!-- ==== Workers worker type has been updated ==== -->
							<xsl:when
								test="exists(peci:Position[@peci:Updated = '1']) and exists(peci:Position/peci:Worker_Type/@peci:priorValue)">
								<xsl:value-of select="true()" />
							</xsl:when>
							<!-- ==== Workers Job Category has been updated ==== -->
							<xsl:when
								test="exists(peci:Position[@peci:Updated = '1']) and exists(peci:Position/peci:Job_Category/@peci:priorValue)">
								<xsl:value-of select="true()" />
							</xsl:when>
							<!-- ==== Workers Job Family has been updated ==== -->
							<xsl:when
								test="exists(peci:Position[@peci:Updated = '1']) and exists(peci:Position/peci:Job_Family/@peci:priorValue)">
								<xsl:value-of select="true()" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="false()" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- ==== Call template IT0001 for only those workers with valid data 
						changes ==== -->
					<xsl:if
						test="
                            ($trueINT0001PositionStatusChange = true() or $ProfessionalCategoryChanged = true()) and
                            ($CompanyChanged = true()
                            or $TerminatedChanged = true()
                            or $CostCenterChanged = true()
                            or $BusinessTitleChanged = true()
                            or $WorkerTypeChanged = true()
                            or $JobCategoryChanged = true()
                            or $JobFamilyChanged = true())">
						<xsl:call-template name="IT0001">
							<xsl:with-param name="Employee_ID" select="$Employee_ID" />
							<xsl:with-param name="Pay_Group" select="$Pay_Group" />
							<xsl:with-param name="TYEL_Code" select="$TYEL_Code" />
							<xsl:with-param name="TYEL_Dept" select="$TYEL_Dept" />
							<xsl:with-param name="City_Number" select="$City_Number" />
							<xsl:with-param name="Company" select="$Company" />
							<xsl:with-param name="Terminated" select="$Terminated" />
							<xsl:with-param name="ProfessionalCategory"
								select="$ProfessionalCategory" />
							<xsl:with-param name="CostCenter" select="$CostCenter" />
							<xsl:with-param name="BusinessTitle" select="$BusinessTitle" />
							<xsl:with-param name="WorkerType" select="$WorkerType" />
							<xsl:with-param name="JobCategory" select="$JobCategory" />
							<xsl:with-param name="JobFamily" select="$JobFamily" />

						</xsl:call-template>
					</xsl:if>
					<!-- ==== END OF INFOTYPE 0001 ==== -->

					<!-- ==== INFOTYPE 0002 ==== -->
					<!-- ==== Legal Last Name Changed Variable ==== -->
					<xsl:variable name="LegalLastNameChanged" as="xs:boolean">
						<xsl:choose>
							<xsl:when
								test="peci:elementChanged(peci:Personal/peci:Legal_Name/peci:Last_Name) = ('CH1', 'CHA', 'CHP')">
								<xsl:value-of select="true()" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="false()" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- ==== Legal Last Name Variable ==== -->
					<xsl:variable name="LegalLastName">
						<xsl:value-of select="peci:Personal/peci:Legal_Name/peci:Last_Name" />
					</xsl:variable>
					<!-- ==== Legal First Name Changed Variable ==== -->
					<xsl:variable name="LegalFirstNameChanged" as="xs:boolean">
						<xsl:choose>
							<xsl:when
								test="peci:elementChanged(peci:Personal/peci:Legal_Name/peci:First_Name) = ('CH1', 'CHA', 'CHP')">
								<xsl:value-of select="true()" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="false()" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- ==== Legal First Name Variable ==== -->
					<xsl:variable name="LegalFirstName">
						<xsl:value-of select="peci:Personal/peci:Legal_Name/peci:First_Name" />
					</xsl:variable>
					<!-- ==== Preferred First Name Changed Variable ==== -->
					<xsl:variable name="PreferredFirstNameChanged" as="xs:boolean">
						<xsl:choose>
							<xsl:when
								test="peci:elementChanged(peci:Personal/peci:Preferred_Name/peci:First_Name) = ('CH1', 'CHA', 'CHP')">
								<xsl:value-of select="true()" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="false()" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- ==== Preferred First Name Variable ==== -->
					<xsl:variable name="PreferredFirstName">
						<xsl:value-of select="peci:Personal/peci:Preferred_Name/peci:First_Name" />
					</xsl:variable>
					<!-- ==== Gender Changed Variable ==== -->
					<xsl:variable name="GenderChanged" as="xs:boolean">
						<xsl:choose>
							<xsl:when
								test="peci:elementChanged(peci:Personal/peci:Gender) = ('CH1', 'CHA', 'CHP')">
								<xsl:value-of select="true()" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="false()" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- ==== Gender Variable ==== -->
					<xsl:variable name="Gender">
						<xsl:value-of select="peci:Personal/peci:Gender" />
					</xsl:variable>
					<!-- ==== Nationality Changed Variable ==== -->
					<xsl:variable name="NationalityChanged" as="xs:boolean">
						<xsl:choose>
							<xsl:when
								test="peci:elementChanged(peci:Personal/peci:Nationality) = ('CH1', 'CHA', 'CHP')">
								<xsl:value-of select="true()" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="false()" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- ==== Nationality Variable ==== -->
					<xsl:variable name="Nationality">
						<xsl:value-of select="peci:Personal/peci:Nationality" />
					</xsl:variable>
					<!-- ==== National Id Changed Variable ==== -->
					<xsl:variable name="NationalIdChanged" as="xs:boolean">
						<xsl:choose>
							<xsl:when
								test="peci:elementChanged(peci:Person_Identification/peci:National_Identifier/peci:National_ID) = ('CH1', 'CHA', 'CHP')">
								<xsl:value-of select="true()" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="false()" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- ==== National Id Variable ==== -->
					<!-- ==== Only output National ID of type FIN-ID === -->

					<xsl:variable name="NationalId">
						<xsl:value-of
							select="peci:Person_Identification[not(@peci:isDeleted = '1')]/peci:National_Identifier[not(@peci:isDeleted = '1') and peci:National_ID_Type='FIN-ID']/peci:National_ID" />
					</xsl:variable>
					<!-- ==== Call template IT0002 for only those workers with valid staffing 
						event or valid data changes ==== -->
					<xsl:if
						test="
                            $Staffing_Event = 'G1'
                            or $LegalLastNameChanged = true()
                            or $LegalFirstNameChanged = true()
                            or $PreferredFirstNameChanged = true()
                            or $GenderChanged = true()
                            or $NationalityChanged = true()
                            or $NationalIdChanged = true()">
						<xsl:call-template name="IT0002">
							<xsl:with-param name="Employee_ID" select="$Employee_ID" />
							<xsl:with-param name="LegalLastName" select="$LegalLastName" />
							<xsl:with-param name="LegalFirstName" select="$LegalFirstName" />
							<xsl:with-param name="PreferredFirstName" select="$PreferredFirstName" />
							<xsl:with-param name="Gender" select="$Gender" />
							<xsl:with-param name="Nationality" select="$Nationality" />
							<xsl:with-param name="NationalId" select="$NationalId" />
						</xsl:call-template>
					</xsl:if>
					<!-- ==== END OF INFOTYPE 0002 ==== -->

					<!-- ==== INFOTYPE 0006 ==== -->
					<!-- ==== Address Line 1 Changed Variable ==== -->
					<xsl:variable name="AddressLine1Changed" as="xs:boolean">
						<xsl:choose>
							<xsl:when
								test="peci:elementChanged(peci:Person_Communication/peci:Address/peci:Address_Line_1) = ('CH1', 'CHA', 'CHP')">
								<xsl:value-of select="true()" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="false()" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- ==== Address Line 1 Variable ==== -->
					<xsl:variable name="AddressLine1">
						<xsl:value-of
							select="peci:Person_Communication/peci:Address[not(@peci:isDeleted = '1')]/peci:Address_Line_1" />
					</xsl:variable>
					<!-- ==== Address Line 3 Changed Variable ==== -->
					<xsl:variable name="AddressLine3Changed" as="xs:boolean">
						<xsl:choose>
							<xsl:when
								test="peci:elementChanged(peci:Person_Communication/peci:Address/peci:Address_Line_3) = ('CH1', 'CHA', 'CHP')">
								<xsl:value-of select="true()" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="false()" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- ==== Address Line 3 Variable ==== -->
					<xsl:variable name="AddressLine3">
						<xsl:value-of
							select="peci:Person_Communication/peci:Address[not(@peci:isDeleted = '1')]/peci:Address_Line_3" />
					</xsl:variable>
					<!-- ==== City Changed Variable ==== -->
					<xsl:variable name="CityChanged" as="xs:boolean">
						<xsl:choose>
							<xsl:when
								test="peci:elementChanged(peci:Person_Communication/peci:Address/peci:City_Subdivision_1) = ('CH1', 'CHA', 'CHP')">
								<xsl:value-of select="true()" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="false()" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- ==== City Variable ==== -->
					<xsl:variable name="City">
						<xsl:value-of
							select="peci:Person_Communication/peci:Address[not(@peci:isDeleted = '1')]/peci:City_Subdivision_1" />
					</xsl:variable>
					<!-- ==== Postal Code Changed Variable ==== -->
					<xsl:variable name="PostalCodeChanged" as="xs:boolean">
						<xsl:choose>
							<xsl:when
								test="peci:elementChanged(peci:Person_Communication/peci:Address/peci:Postal_Code) = ('CH1', 'CHA', 'CHP')">
								<xsl:value-of select="true()" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="false()" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- ==== Postal Code Variable ==== -->

					<!-- ==== Postal code, only numbers valid, to avoid payslip failure 
						on the receiving application, Nov 13 2018 ==== -->
					<xsl:variable name="PostalCode">
						<xsl:value-of
							select="peci:Person_Communication/peci:Address[not(@peci:isDeleted = '1')]/peci:Postal_Code" />
					</xsl:variable>
					<xsl:choose>
						<xsl:when test="$PostalCode = ''">
						</xsl:when>
						<xsl:when test="number($PostalCode)">
						</xsl:when>
						<xsl:otherwise>
							<xsl:variable name="Message"
								select="'Worker has non-numeric postal code, excluded from the output and reported as an error'" />
							<element etv:severity="error" etv:targetWID="{$Employee_WID}"
								etv:message="{$Message}" xtt:omit="true" />
						</xsl:otherwise>
					</xsl:choose>
					<!-- ==== Call template IT0006 for only those workers with valid staffing 
						event and valid data changes ==== -->
					<xsl:if
						test="($Staffing_Event = 'G1' and exists(peci:Person_Communication)) or $AddressLine1Changed = true() or $CityChanged = true() or $PostalCodeChanged = true() or $AddressLine3Changed = true()">
						<xsl:call-template name="IT0006">
							<xsl:with-param name="Employee_ID" select="$Employee_ID" />
							<xsl:with-param name="AddressLine1" select="$AddressLine1" />
							<xsl:with-param name="AddressLine3" select="$AddressLine3" />
							<xsl:with-param name="City" select="$City" />
							<xsl:with-param name="PostalCode" select="$PostalCode" />
						</xsl:call-template>
					</xsl:if>
					<!-- ==== END OF INFOTYPE 0006 ==== -->

					<!-- ==== INFOTYPE 0007 ==== -->
					<!-- ==== Scheduled Weekly Hours Changed Variable ==== -->
					<xsl:variable name="ScheduledWeeklyHoursChanged" as="xs:boolean">
						<xsl:choose>
							<xsl:when
								test="peci:elementChanged(peci:Position/peci:Scheduled_Weekly_Hours) = ('CH1', 'CHA', 'CHP')">
								<xsl:value-of select="true()" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="false()" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- ==== Scheduled Weekly Hours Variable ==== -->
					<xsl:variable name="ScheduledWeeklyHours">
						<xsl:value-of
							select="peci:Position[not(peci:Position_End_Date/@peci:isAdded) and not(peci:Position_End_Date/@peci:isUpdated)]/peci:Scheduled_Weekly_Hours" />
					</xsl:variable>
					<!-- ==== Worker Position Changed Variable ==== -->
					<xsl:variable name="trueINT0007PositionChange" as="xs:boolean">
						<xsl:choose>
							<xsl:when
								test="exists(peci:Position[@peci:isAdded = '1']) or (exists(peci:Position[@peci:isUpdated = '1']) and ($ScheduledWeeklyHoursChanged = true()) and (exists(peci:Position/peci:Scheduled_Weekly_Hours/@peci:priorValue)))">
								<xsl:value-of select="true()" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="false()" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- ==== Call template IT0007 for only those workers with valid data 
						changes ==== -->
					<xsl:if
						test="$ScheduledWeeklyHoursChanged = true() and $trueINT0007PositionChange = true()">
						<xsl:call-template name="IT0007">
							<xsl:with-param name="Employee_ID" select="$Employee_ID" />
							<xsl:with-param name="ScheduledWeeklyHours"
								select="$ScheduledWeeklyHours" />
						</xsl:call-template>
					</xsl:if>
					<!-- ==== END OF INFOTYPE 0007 ==== -->

					<!-- ==== INFOTYPE 0008 ==== -->
					<xsl:choose>

						<!-- === 20.09.2018 - exclude all statutory increases from the output 
							as processed in payroll and updated to Workday ==== -->
						<!-- <xsl:when test="../peci:Effective_Change[2]/peci:Compensation/peci:Compensation_Change_Reason 
							= '6'"> <xsl:variable name="Message"> <xsl:value-of select="'Statutory Increase 
							- Record Excluded'" /> </xsl:variable> <element etv:severity="info" etv:targetWID="{$Employee_WID}" 
							etv:message="{$Message}" xtt:omit="true" /> </xsl:when> -->
						<!-- <xsl:when test="peci:Compensation/peci:Compensation_Change_Reason 
							= '6'"> <xsl:variable name="Message"> <xsl:value-of select="'Statutory Increase 
							- Record Excluded'" /> </xsl:variable> <element etv:severity="info" etv:targetWID="{$Employee_WID}" 
							etv:message="{$Message}" xtt:omit="true" /> </xsl:when> -->
						<xsl:when
							test="peci:Compensation_Plans[@peci:isAdded = '1' or @peci:isUpdated = '1']/peci:Salary_and_Hourly_Plan/peci:Compensation_Plan = 'Finland_Hourly_Plan_219'">
							<xsl:variable name="Message">
								<xsl:value-of select="'Increase for Hourly Plan 219 - Record Excluded'" />
							</xsl:variable>
							<element etv:severity="error" etv:targetWID="{$Employee_WID}"
								etv:message="{$Message}" xtt:omit="true" />
						</xsl:when>

						<xsl:otherwise>
							<!-- ==== When a worker has had more than 5 changes to their IT008 
								section then add a notification to the integration event ==== -->
							<xsl:if
								test="(count(peci:Compensation_Earnings_and_Deductions[@peci:isAdded = '1' or @peci:isUpdated = '1'][contains(peci:External_Payroll_Code, 'IT008')])
                                + count(peci:Compensation_Plans[@peci:isAdded = '1']/peci:Salary_and_Hourly_Plan)
                                + count(peci:Compensation_Plans[@peci:isUpdated = '1']/peci:Salary_and_Hourly_Plan[@peci:isUpdated = '1']) > 5)
                                or (exists (peci:Collective_Agreement[@peci:isAdded = '1' or @peci:isUpdated = '1'])
                                and (count(peci:Compensation_Earnings_and_Deductions[contains(peci:External_Payroll_Code, 'IT008')])
                                + count(peci:Compensation_Plans/peci:Salary_and_Hourly_Plan) > 5))">
								<xsl:variable name="Message">
									<xsl:value-of
										select="'There are more than 5 additions or changes to the external earnings. Please review manually.'" />
								</xsl:variable>
								<element etv:severity="error" etv:targetWID="{$Employee_WID}"
									etv:message="{$Message}" xtt:omit="true" />
							</xsl:if>
							<xsl:if
								test="../peci:Effective_Change/peci:Compensation[not(exists(peci:Position_End_Date/@peci:isAdded))]/peci:Compensation_Change_Reason = '6'">
								<!-- test="../peci:Effective_Change/peci:Compensation[last()]/peci:Compensation_Change_Reason[last()] 
									= '6'"> -->
								<xsl:variable name="Message">
									<xsl:value-of select="'Statutory Increase'" />
								</xsl:variable>
								<element etv:severity="error" etv:targetWID="{$Employee_WID}"
									etv:message="{$Message}" xtt:omit="true" />
							</xsl:if>
							<!-- ==== When a worker has had an applicable change to their Compensation 
								Plans (IT0008) then call template IT0008 ==== -->
							<xsl:if
								test="(exists(peci:Compensation_Earnings_and_Deductions[@peci:isAdded = '1' or @peci:isUpdated = '1'][contains(peci:External_Payroll_Code, 'IT008')])
                                or exists(peci:Compensation_Plans[@peci:isAdded = '1']/peci:Salary_and_Hourly_Plan)
                                or exists(peci:Compensation_Plans[@peci:isUpdated = '1']/peci:Salary_and_Hourly_Plan[@peci:isAdded = '1' or @peci:isUpdated = '1']))
                                or (exists (peci:Collective_Agreement[@peci:isAdded = '1' or @peci:isUpdated = '1'])
                                and (exists(peci:Compensation_Earnings_and_Deductions[contains(peci:External_Payroll_Code, 'IT008')])                            
                                or exists(peci:Compensation_Plans/peci:Salary_and_Hourly_Plan)))">
								<xsl:choose>
									<!-- ==== When a worker has had a change in their collective agreement 
										add a notification to the integration event ==== -->
									<!-- ==== Send warning if IT0008 included === -->
									<xsl:when
										test="exists(peci:Collective_Agreement[@peci:isAdded = '1' or @peci:isUpdated = '1'])">
										<xsl:variable name="Message"
											select="'Worker has had a change 
											in their Collective Agreements which may affect their Comepnsation Elements. 
											Manual updates required.'" />
										<!-- <element etv:severity="error" etv:targetWID="{$Employee_WID}" 
											etv:message="{$Message}" xtt:omit="true" /> -->
										<element etv:severity="Warning" etv:targetWID="{$Employee_WID}"
											etv:message="{$Message}" />

										<xsl:call-template name="IT0008">
											<xsl:with-param name="Employee_ID" select="$Employee_ID" />
											<xsl:with-param name="Staffing_Event" select="$Staffing_Event" />
											<xsl:with-param name="PayScaleType" select="$PayScaleType" />
											<xsl:with-param name="PayScaleLevel" select="$PayScaleLevel" />
											<xsl:with-param name="CompChangeReason"
												select="$CompChangeReason" />
											<xsl:with-param name="HireDate" select="$HireDate" />
											<xsl:with-param name="EffectiveDate" select="$Effective_Date" />
										</xsl:call-template>

									</xsl:when>
									<xsl:otherwise>
										<xsl:call-template name="IT0008">
											<xsl:with-param name="Employee_ID" select="$Employee_ID" />
											<xsl:with-param name="Staffing_Event" select="$Staffing_Event" />
											<xsl:with-param name="PayScaleType" select="$PayScaleType" />
											<xsl:with-param name="PayScaleLevel" select="$PayScaleLevel" />
											<xsl:with-param name="CompChangeReason"
												select="$CompChangeReason" />
											<xsl:with-param name="HireDate" select="$HireDate" />
											<xsl:with-param name="EffectiveDate" select="$Effective_Date" />
										</xsl:call-template>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:if>
						</xsl:otherwise>
					</xsl:choose>
					<!-- ==== END OF INFOTYPE 0008 ==== -->

					<!-- ==== INFOTYPE 0009 ==== -->
					<xsl:for-each select="peci:Payment_Election">
						<!-- ==== IBAN Changed Variable ==== -->
						<xsl:variable name="IBANChanged" as="xs:boolean">
							<xsl:choose>
								<xsl:when
									test="peci:elementChanged(peci:IBAN) = ('CH1', 'CHA', 'CHP')">
									<xsl:value-of select="true()" />
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="false()" />
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<!-- ==== IBAN Variable ==== -->
						<xsl:variable name="IBAN">
							<xsl:value-of select="translate(peci:IBAN,' ','')" />
						</xsl:variable>
						<!-- ==== Call template IT0009 for only those workers with valid data 
							changes ==== -->
						<xsl:if test="$IBANChanged = true()">
							<xsl:call-template name="IT0009">
								<xsl:with-param name="Employee_ID" select="$Employee_ID" />
								<xsl:with-param name="IBAN" select="$IBAN" />
							</xsl:call-template>
						</xsl:if>
					</xsl:for-each>
					<!-- ==== END OF INFOTYPE 0009 ==== -->
					<!-- ==== INFOTYPE 014 === -->
					<!-- ==== ALWAYS ADD MOBILE PHONE ALLOWANCE IF IT EXISTS WHEN SALARY 
						(0008) CHANGE INCLUDED IN OUTPUT -->
					<!-- 25.06.2019 - Changed again only to be sent when a hiring or pay group change event-->	
					<xsl:choose>
						<xsl:when
							test="../peci:Effective_Change/peci:Compensation/peci:Compensation_Change_Reason = '6'">
							<xsl:variable name="Message">
								<xsl:value-of select="'Statutory Increase - Record Excluded'" />
							</xsl:variable>
							<element etv:severity="error" etv:targetWID="{$Employee_WID}"
								etv:message="{$Message}" xtt:omit="true" />
						</xsl:when>

						<xsl:when
						      test="$new_hire = true()">
<!-- 						  test="(exists(peci:Compensation_Plans[@peci:isAdded = '1']/peci:Salary_and_Hourly_Plan) -->
<!--                                 or exists(peci:Compensation_Plans[@peci:isUpdated = '1']/peci:Salary_and_Hourly_Plan[@peci:isAdded = '1' or @peci:isUpdated = '1'])) -->
<!--                                 or (exists (peci:Collective_Agreement[@peci:isAdded = '1' or @peci:isUpdated = '1']) -->
<!--                                 and (exists(peci:Compensation_Earnings_and_Deductions[contains(peci:External_Payroll_Code, 'IT008')]) -->
<!--                                 or exists(peci:Compensation_Plans/peci:Salary_and_Hourly_Plan))) -->
<!--                                 and $new_hire = true() "> -->
							<xsl:for-each
								select="(peci:Compensation_Earnings_and_Deductions[contains(peci:External_Payroll_Code, 'IT0014_631')])">
								<xsl:variable name="ExternalPayrollCode" select="peci:External_Payroll_Code" />
								<xsl:variable name="ExternalPayrollAmount" select="peci:Amount" />
								<xsl:choose>
									<xsl:when test="$ExternalPayrollCode = 'IT0014_631'">
										<xsl:call-template name="IT0014">
											<xsl:with-param name="Employee_ID" select="$Employee_ID" />
											<xsl:with-param name="ExternalPayrollCode"
												select="$ExternalPayrollCode" />
											<xsl:with-param name="ExternalPayrollAmount"
												select="$ExternalPayrollAmount" />
										</xsl:call-template>
									</xsl:when>
								</xsl:choose>
							</xsl:for-each>
						</xsl:when>
					</xsl:choose>

					<!-- ==== INFOTYPE 0014 ==== -->
					<!-- ==== For each External Earning and Deduction that has been added or updated, with a code IT0014, call template IT0014 ==== -->
					<!-- ==== Always exclude mobile phone allowances as handled in previous	step === -->
					<xsl:for-each
						select="(peci:Compensation_Earnings_and_Deductions[@peci:isAdded = '1' or @peci:isUpdated = '1'][contains(peci:External_Payroll_Code, 'IT0014')])">
						<xsl:variable name="ExternalPayrollCode" select="peci:External_Payroll_Code" />
						<xsl:variable name="ExternalPayrollAmount" select="peci:Amount" />
						<xsl:choose>
							<xsl:when
								test="$ExternalPayrollCode != 'IT0014_631' and $ExternalPayrollCode != 'IT0014_125'">
								<xsl:call-template name="IT0014">
									<xsl:with-param name="Employee_ID" select="$Employee_ID" />
									<xsl:with-param name="ExternalPayrollCode"
										select="$ExternalPayrollCode" />
									<xsl:with-param name="ExternalPayrollAmount"
										select="$ExternalPayrollAmount" />
								</xsl:call-template>
							</xsl:when>
						</xsl:choose>
					</xsl:for-each>
					<!-- ==== END OF INFOTYPE 0014 ==== -->

					<!-- ==== INFOTYPE 0016 ==== -->
					<!-- ==== Contract Type Changed Variable ==== -->
					<!-- 01.07.2019 - Logic has been changed as changed detection on Additional_Information not possible -->
					<!-- Contract end date change detection on standard contract field, but end date picked up field override -->
					<!-- as active contract end date not available in standard output?? -->
					<xsl:if
						test="exists(peci:Additional_Information/ptdf:Contract_End_Date) and not(exists(following-sibling::peci:Effective_Change/peci:Additional_Information/ptdf:Contract_End_Date))">
						<xsl:variable name="ContractTypeChanged" as="xs:boolean">
							<xsl:choose>
								<xsl:when
									test="peci:elementChanged(peci:Additional_Information/ptdf:Contract_Type) = ('CH1', 'CHA', 'CHP')">
									<xsl:value-of select="true()" />
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="false()" />
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<!-- ==== Contract Type Variable ==== -->
						<xsl:variable name="ContractType">
							<xsl:value-of select="peci:Additional_Information/ptdf:Contract_Type" />
						</xsl:variable>
						<!-- ==== Contract End Date Changed Variable ==== -->
						<xsl:variable name="ContractEndDateChanged" as="xs:boolean">
							<xsl:choose>
								<xsl:when
									test="peci:elementChanged(peci:Additional_Information/ptdf:Contract_End_Date) = ('CH1', 'CHA', 'CHP')">
									<!--					
										test="exists(peci:Employee_Contract[@peci:isAdded = '1'])">	-->
									<xsl:value-of select="true()" />
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="false()" />
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<!-- ==== Contract End Date Variable ==== -->
						<xsl:variable name="ContractEndDate">
							<xsl:choose>
								<xsl:when test="exists(peci:Additional_Information/ptdf:Contract_End_Date[@peci:isDeleted = '1'])">
									<xsl:value-of select="''" />
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="peci:Additional_Information/ptdf:Contract_End_Date" />
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<!-- ==== Additional Information Change variable ==== -->
						<xsl:variable name="trueINT0016AdditionalInformationChange"
							as="xs:boolean">
							<xsl:choose>
								<xsl:when
									test="exists(peci:Additional_Information/ptdf:Contract_End_Date[@peci:isAdded = '1']) or (exists(peci:Additional_Information[@peci:isUpdated = '1']/ptdf:Contract_End_Date and xs:date(peci:Additional_Information/ptdf:Contract_End_Date) &gt; xs:date(peci:Additional_Information/ptdf:Contract_Start_Date)) and ($ContractTypeChanged = true() or $ContractEndDateChanged = true()))">
									<!--							test="exists(peci:Additional_Information[@peci:isAdded = '1']) or (exists(peci:Additional_Information[@peci:isUpdated = '1']) and ($ContractTypeChanged = true() or $ContractEndDateChanged = true()) and (exists(peci:Additional_Information/ptdf:Contract_End_Date/@peci:priorValue) or exists(peci:Additional_Information/ptdf:Contract_Type/@peci:priorValue)))">
								test="exists($ContractTypeChanged = true() or $ContractEndDateChanged = true())"> -->
									<xsl:value-of select="true()" />
								</xsl:when>
								<xsl:when
									test="exists(peci:Additional_Information/ptdf:Contract_Type[@peci:isAdded = '1']) or (exists(peci:Additional_Information/ptdf:Contract_Type[@peci:isUpdated = '1']) and ($ContractTypeChanged = true() or $ContractEndDateChanged = true()))">
									<xsl:value-of select="true()" />
								</xsl:when>
								<xsl:when
									test="exists(peci:Employee_Contract[@peci:isAdded = '1'])">
									<xsl:value-of select="true()" />
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="false()" />
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<!-- ==== Call template IT0016 for only those workers with valid data 
						changes ==== -->
						<xsl:if test="$trueINT0016AdditionalInformationChange = true()">
							<xsl:call-template name="IT0016">
								<xsl:with-param name="Employee_ID" select="$Employee_ID" />
								<xsl:with-param name="ContractType" select="$ContractType" />
								<xsl:with-param name="ContractEndDate" select="$ContractEndDate" />
							</xsl:call-template>
						</xsl:if>
					</xsl:if>
						<!-- ==== END OF INFOTYPE 0016 ==== -->
					<!-- ==== INFOTYPE 0041 ==== -->
					<!-- ==== Hire Date Changed varible ==== -->
					<xsl:variable name="HireDateChanged" as="xs:boolean">
						<xsl:choose>
							<xsl:when
								test="peci:elementChanged(peci:Worker_Status/peci:Hire_Date) = ('CH1', 'CHA', 'CHP')">
								<xsl:value-of select="true()" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="false()" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- ==== Seniority Date Changed varible ==== -->
					<xsl:variable name="SeniorityDateChanged" as="xs:boolean">
						<xsl:choose>
							<xsl:when
								test="peci:elementChanged(peci:Worker_Status/peci:Seniority_Date) = ('CH1', 'CHA', 'CHP')">
								<xsl:value-of select="true()" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="false()" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- ==== Seniority Date variable ==== -->
					<xsl:variable name="SeniorityDate">
						<xsl:value-of select="peci:Worker_Status/peci:Seniority_Date" />
					</xsl:variable>
					<!-- ==== Pay Group Assignment Date Changed variable ==== -->
					<!-- 01.07.2019 - Field override for PayGroupAssignment removed due to performance issues -->
					<!-- Logic change to send hire date when new hire attribute is true (i.e. new hires and pay group changes) -->
					<xsl:variable name="PayGroupAssignmentDateChanged" as="xs:boolean">
						<xsl:choose>
							<xsl:when
								test="$new_hire = true()">
<!-- 								test="peci:elementChanged(peci:Additional_Information/ptdf:Pay_Group_Assignment_Date) = ('CH1', 'CHA', 'CHP')"> -->
								<xsl:value-of select="true()" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="false()" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- ==== Pay Group Assignment Date variable ==== -->
					<xsl:variable name="PayGroupAssignmentDate">
						<xsl:value-of
							select="xs:date(substring(peci:Worker_Status/peci:Hire_Date, 0, 11))" />
<!-- 							select="substring(peci:Additional_Information/ptdf:Pay_Group_Assignment_Date, 0, 11)" /> -->
					</xsl:variable>
					<!-- ==== Variable to determine if worker has had an applicable teacher 
						==== -->
					<xsl:variable name="trueINT0041StatusChange" as="xs:boolean">
						<xsl:choose>
							<xsl:when
								test="exists(peci:Worker_Status[@peci:isAdded = '1']) or (exists(peci:Worker_Status[@peci:isUpdated = '1']) and (($HireDateChanged = true() or $SeniorityDateChanged = true()) and (exists(peci:Worker_Status/peci:Hire_Date/@peci:priorValue) or exists(peci:Worker_Status/peci:Seniority_Date/@peci:priorValue)) or (exists(peci:Additional_Information/ptdf:Pay_Group_Assignment_Date/@peci:priorValue) and $PayGroupAssignmentDateChanged = true())))">
								<xsl:value-of select="true()" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="false()" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- ==== Call template IT0041 for only those workers with valid data 
						changes ==== -->
					<xsl:if test="$new_hire = true() or $trueINT0041StatusChange = true()">
						<xsl:call-template name="IT0041">
							<xsl:with-param name="Employee_ID" select="$Employee_ID" />
							<xsl:with-param name="HireDate" select="$HireDate" />
							<xsl:with-param name="SeniorityDate" select="$SeniorityDate" />
							<xsl:with-param name="PayGroupAssignmentDate"
								select="$PayGroupAssignmentDate" />
						</xsl:call-template>
					</xsl:if>
					<!-- ==== END OF INFOTYPE 0041 ==== -->

					<!-- ==== INFOTYPE 9010 ==== -->
					<!-- ==== Call template IT9010 for only those workers with valid laeve 
						of absence additions or updates ==== -->
					<xsl:for-each
						select="peci:Leave_of_Absence[not(@peci:isDeleted = '1')][not(exists(../peci:Leave_of_Absence[@peci:isDeleted = '1']))]">
						<xsl:call-template name="IT9010">
							<xsl:with-param name="Employee_ID" select="$Employee_ID" />
						</xsl:call-template>
					</xsl:for-each>
					<!-- ==== END OF INFOTYPE 9010 ==== -->

					<!-- ==== INFOTYPE 2001 ==== -->
					<!-- ==== Call template IT2001 for only those workers with valid time 
						off additions or updates ==== -->
					<!-- ==== Exclude staff with Working time reductions entries ==== -->
					<xsl:for-each
						select="peci:Time_Off_Earnings_and_Deductions[@peci:isAdded = '1' or @peci:isUpdated = '1']">
						<xsl:if
							test="not((contains(../peci:Additional_Information/ptdf:Collective_Agreement/ptdf:Collective_Agreement_ID, 'Staff')) and peci:External_Payroll_Code = '460_461')">
							<xsl:call-template name="IT2001">
								<xsl:with-param name="Employee_ID" select="$Employee_ID" />
								<xsl:with-param name="Pay_Group" select="$Pay_Group" />
							</xsl:call-template>
						</xsl:if>
					</xsl:for-each>


					<!-- ==== END OF INFOTYPE 2001 ==== -->

					<!-- ==== INFOTYPE 0015 OTP ==== -->
					<!-- ==== Call template IT0015 for only those workers with valid one 
						time payments additions or updates ==== -->
					<xsl:for-each
						select="peci:Compensation_One_Time_Payment[@peci:isAdded = '1' or @peci:isUpdated = '1']">
						<xsl:choose>
							<xsl:when test="peci:Reason = 'Bonus_not_for_payroll'">
								<!-- ==== Not to be included in the output === -->
							</xsl:when>
							<xsl:otherwise>
								<xsl:call-template name="IT0015">
									<xsl:with-param name="Employee_ID" select="$Employee_ID" />
									<xsl:with-param name="Effective_Date" select="$Effective_Date" />
									<xsl:with-param name="Amount" select="'amount'" />
								</xsl:call-template>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
					<!-- ==== Call template IT0015 for only those workers with valid one -->
					<!-- time payments deletions ==== -->
					<xsl:for-each
						select="peci:Compensation_One_Time_Payment[@peci:isDeleted = '1']">
						<xsl:choose>
							<xsl:when
								test="peci:Compensation_One_Time_Payment/peci:Reason = 'Bonus_not_for_payroll'">
								<!-- ==== Not to be included in the output === -->
							</xsl:when>
							<xsl:otherwise>
								<xsl:call-template name="IT0015">
									<xsl:with-param name="Employee_ID" select="$Employee_ID" />
									<xsl:with-param name="Effective_Date" select="$Effective_Date" />
									<xsl:with-param name="Amount" select="'zero'" />
								</xsl:call-template>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
					<!-- ==== END OF INFOTYPE 0015 ==== -->

					<!-- ==== INFOTYPE 0015 OTP ==== -->
					<!-- ==== For each External Earning and Deduction that has been added 
						or updated, with a code IT0014, call template IT0015 ==== -->
					<xsl:for-each
						select="peci:Compensation_Earnings_and_Deductions[@peci:isAdded = '1' or @peci:isUpdated = '1'][contains(peci:External_Payroll_Code, 'IT0015')]">
						<xsl:call-template name="IT0015">
							<xsl:with-param name="Employee_ID" select="$Employee_ID" />
							<xsl:with-param name="Effective_Date" select="$Effective_Date" />
						</xsl:call-template>
					</xsl:for-each>
					<!-- ==== END OF INFOTYPE 0015 ==== -->



				</xsl:otherwise>
			</xsl:choose>

		</Record>

	</xsl:template>

	<!-- ==== INFOTYPE 0000 TEMPLATE ==== -->
	<xsl:template name="IT0000">
		<xsl:param name="Employee_ID" />
		<xsl:param name="Staffing_Event" />
		<xsl:param name="TerminationDate" />
		<xsl:param name="HireDate" />
		<xsl:param name="OriginalHireDate" />
		<xsl:param name="Effective_Moment" select="peci:Effective_Moment" />

		<IT0000 xtt:endTag="&#xd;&#xa;">
			<PERNR xtt:fixedLength="8">
				<xsl:value-of select="$Employee_ID" />
			</PERNR>
			<INFTY xtt:fixedLength="4">
				<xsl:value-of select="'0000'" />
			</INFTY>
			<BLANK xtt:fixedLength="4">
				<xsl:value-of select="''" />
			</BLANK>
			<ENDDA xtt:fixedLength="8" xtt:dateFormat="yyyyMMdd">
				<xsl:choose>
					<xsl:when test="$Staffing_Event = 'G3' and $TerminationDate != ''">
						<xsl:value-of select="xs:date(substring($TerminationDate, 0, 11))" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="'99991231'" />
					</xsl:otherwise>
				</xsl:choose>
			</ENDDA>
			<BEGDA xtt:fixedLength="8" xtt:dateFormat="yyyyMMdd">
				<xsl:choose>
					<xsl:when test="$Staffing_Event = ('G1', 'G4')">
						<xsl:value-of select="xs:date(substring($HireDate, 0, 11))" />
					</xsl:when>
					<xsl:when test="$Staffing_Event = ('G2', 'G5')">
						<xsl:value-of select="xs:date(substring($Effective_Moment, 0, 11))" />
					</xsl:when>
					<xsl:when test="$Staffing_Event = 'G3' and $TerminationDate != ''">
						<!-- == 20.09.2018 == -->
						<!-- == Remove logic to send first not working day == -->
						<!-- <xsl:value-of select="xs:date(xs:date(substring($TerminationDate, 
							0, 11)) + 1 * xs:dayTimeDuration('P1D'))"/> -->
						<xsl:value-of select="xs:date(substring($TerminationDate, 0, 11))" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="xs:date(substring($Effective_Moment, 0, 11))" />
					</xsl:otherwise>
				</xsl:choose>
			</BEGDA>
			<MASSN xtt:fixedLength="2">
				<xsl:value-of select="$Staffing_Event" />
			</MASSN>
			<MASSN1 xtt:fixedLength="1">
				<xsl:choose>
					<xsl:when test="peci:Derived_Event_Code = ('TERM', 'TERM-C', 'PCO')">
						<xsl:value-of select="'1'" />
					</xsl:when>
					<xsl:when
						test="peci:Derived_Event_Code = ('PCI', 'TERM-R') or (peci:Derived_Event_Code = 'HIR' and xs:date(substring($HireDate, 0, 11)) = xs:date(substring($OriginalHireDate, 0, 11)))">
						<xsl:value-of select="'2'" />
					</xsl:when>
					<xsl:when
						test="xs:date(substring($HireDate, 0, 11)) &gt; xs:date(substring($OriginalHireDate, 0, 11))">
						<xsl:value-of select="'3'" />
					</xsl:when>
				</xsl:choose>
			</MASSN1>
		</IT0000>
	</xsl:template>

	<!-- ==== INFOTYPE 0001 TEMPLATE ==== -->
	<xsl:template name="IT0001">
		<xsl:param name="Employee_ID" />
		<xsl:param name="Pay_Group" />
		<xsl:param name="TYEL_Code" />
		<xsl:param name="TYEL_Dept" />
		<xsl:param name="City_Number" />
		<xsl:param name="Company" />
		<xsl:param name="Terminated" />
		<xsl:param name="ProfessionalCategory" />
		<xsl:param name="CostCenter" />
		<xsl:param name="BusinessTitle" />
		<xsl:param name="WorkerType" />
		<xsl:param name="JobCategory" />
		<xsl:param name="JobFamily" />
		<xsl:param name="Effective_Moment" select="peci:Effective_Moment" />

		<IT0001 xtt:endTag="&#xd;&#xa;">
			<!-- ==== Workers Employee Id ==== -->
			<PERNR xtt:fixedLength="8">
				<xsl:value-of select="$Employee_ID" />
			</PERNR>
			<!-- ==== Hardcoded 0001 ==== -->
			<INFTY xtt:fixedLength="4">
				<xsl:value-of select="'0001'" />
			</INFTY>
			<!-- ==== BLANK ==== -->
			<BLANK xtt:fixedLength="4">
				<xsl:value-of select="''" />
			</BLANK>
			<!-- ==== Effective Moment ==== -->
			<BEGDA xtt:fixedLength="8" xtt:dateFormat="yyyyMMdd">
				<xsl:value-of select="xs:date(substring($Effective_Moment, 0, 11))" />
			</BEGDA>
			<!-- ==== Workers Company ==== -->
			<BUKRS xtt:fixedLength="4">
				<xsl:value-of select="$Company" />
			</BUKRS>
			<!-- ==== If Worker is terminated then 1 Else 0 ==== -->
			<PERSG xtt:fixedLength="1">
				<xsl:choose>
					<xsl:when test="$Terminated = 1">
						<xsl:value-of select="'9'" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="'0'" />
					</xsl:otherwise>
				</xsl:choose>
			</PERSG>
			<!-- ==== Workers professional category ==== -->
			<PERSK xtt:fixedLength="2">
				<xsl:value-of select="$ProfessionalCategory" />
			</PERSK>
			<!-- ==== Workers cost center ==== -->
			<KOSTL xtt:fixedLength="10">
				<xsl:value-of select="translate($CostCenter,'G','0')" />
			</KOSTL>
			<!-- ==== Business Title ==== -->
			<PLSTX xtt:fixedLength="25">
				<xsl:value-of select="$BusinessTitle" />
			</PLSTX>
			<!-- ==== Workers Pay Group ==== -->
			<SACHA xtt:fixedLength="3">
				<xsl:value-of select="$Pay_Group" />
			</SACHA>
			<!-- ==== If worker cost center is 2713110 then 442111 ==== -->
			<!-- ==== If worker type is Expat then 441060 ==== -->
			<!-- ==== If worker job category is Operative Supervisor then 441006 ==== -->
			<!-- ==== If worker job family is Field Trainer or Project Manager (Delivery-Operative) 
				then 441006 ==== -->
			<!-- ==== If worker pay group is F03 or F04 then 440000 ==== -->
			<!-- ==== If worker pay group is F02 or F16 or F17 then 441000 ==== -->
			<!-- ==== Else this is left blank ==== -->
			<TILNO xtt:fixedLength="10">
				<xsl:choose>
					<xsl:when test="$CostCenter = '2713110'">
						<xsl:value-of select="'442111'" />
					</xsl:when>
					<xsl:when test="$WorkerType = 'Expat'">
						<xsl:value-of select="'441060'" />
					</xsl:when>
					<xsl:when test="$JobCategory = 'Operative_Supervisor'">
						<xsl:value-of select="'441006'" />
					</xsl:when>
					<xsl:when
						test="$JobFamily = 'Field Trainer or Project Manager (Delivery-Operative)'">
						<xsl:value-of select="'441006'" />
					</xsl:when>
					<xsl:when test="$Pay_Group = ('F03', 'F04')">
						<xsl:value-of select="'440000'" />
					</xsl:when>
					<xsl:when test="$Pay_Group = ('F02', 'F16', 'F17')">
						<xsl:value-of select="'441000'" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="''" />
					</xsl:otherwise>
				</xsl:choose>
			</TILNO>
			<!-- ==== Workers TYEL Code, based on function mapping ==== -->
			<TYELCODE xtt:fixedLength="3">
				<xsl:value-of select="$TYEL_Code" />
			</TYELCODE>
			<!-- ==== Workers TYEL Department, based on function mapping ==== -->
			<TYELDEP xtt:fixedLength="2">
				<xsl:value-of select="$TYEL_Dept" />
			</TYELDEP>
			<!-- ==== Workers City Number ==== -->
			<CITYNO xtt:fixedLength="8">
				<xsl:value-of select="$City_Number" />
			</CITYNO>
		</IT0001>
	</xsl:template>

	<!-- ==== INFOTYPE 0002 TEMPLATE ==== -->
	<xsl:template name="IT0002">
		<xsl:param name="Employee_ID" />
		<xsl:param name="LegalLastName" />
		<xsl:param name="LegalFirstName" />
		<xsl:param name="PreferredFirstName" />
		<xsl:param name="Gender" />
		<xsl:param name="Nationality" />
		<xsl:param name="NationalId" />
		<xsl:param name="Effective_Moment" select="peci:Effective_Moment" />

		<IT0002 xtt:endTag="&#xd;&#xa;">
			<!-- ==== Workers Employee Id ==== -->
			<PERNR xtt:fixedLength="8">
				<xsl:value-of select="$Employee_ID" />
			</PERNR>
			<!-- ==== Hardcoded 0002 ==== -->
			<INFTY xtt:fixedLength="4">
				<xsl:value-of select="'0002'" />
			</INFTY>
			<!-- ==== BLANK ==== -->
			<BLANK xtt:fixedLength="4">
				<xsl:value-of select="''" />
			</BLANK>
			<!-- ==== Effective Moment ==== -->
			<BEGDA xtt:fixedLength="8" xtt:dateFormat="yyyyMMdd">
				<xsl:value-of select="xs:date(substring($Effective_Moment, 0, 11))" />
			</BEGDA>
			<!-- ==== Workers Legal Last Name ==== -->
			<NACHN xtt:fixedLength="40">
				<xsl:value-of select="$LegalLastName" />
			</NACHN>
			<!-- ==== Workers Legal First Name ==== -->
			<VORNA xtt:fixedLength="40">
				<xsl:value-of select="$LegalFirstName" />
			</VORNA>
			<!-- ==== Workers Preferred First Name ==== -->
			<RUFNM xtt:fixedLength="40">
				<xsl:value-of select="$PreferredFirstName" />
			</RUFNM>
			<!-- ==== Workers Gender ==== -->
			<GESCH xtt:fixedLength="1">
				<xsl:value-of select="$Gender" />
			</GESCH>
			<!-- ==== Workers Nationality ==== -->
			<NATIO xtt:fixedLength="3">
				<xsl:value-of select="$Nationality" />
			</NATIO>
			<!-- ==== Workers Hardcoded SF ==== -->
			<SPRSL xtt:fixedLength="2">
				<xsl:value-of select="'SF'" />
			</SPRSL>
			<!-- ==== Workers National Id ==== -->
			<PERID xtt:fixedLength="20">
				<xsl:value-of select="$NationalId" />
			</PERID>
		</IT0002>
	</xsl:template>

	<!-- ==== INFOTYPE 0006 TEMPLATE ==== -->
	<xsl:template name="IT0006">
		<xsl:param name="Employee_ID" />
		<xsl:param name="AddressLine1" />
		<xsl:param name="AddressLine3" />
		<xsl:param name="City" />
		<xsl:param name="PostalCode" />
		<xsl:param name="Effective_Moment" select="peci:Effective_Moment" />

		<IT0006 xtt:endTag="&#xd;&#xa;">
			<!-- ==== Workers Employee Id ==== -->
			<PERNR xtt:fixedLength="8">
				<xsl:value-of select="$Employee_ID" />
			</PERNR>
			<!-- ==== Hardcoded 0006 ==== -->
			<INFTY xtt:fixedLength="4">
				<xsl:value-of select="'0006'" />
			</INFTY>
			<!-- ==== BLANK ==== -->
			<BLANK xtt:fixedLength="4">
				<xsl:value-of select="''" />
			</BLANK>
			<!-- ==== Effective Moment ==== -->
			<BEGDA xtt:fixedLength="8" xtt:dateFormat="yyyyMMdd">
				<xsl:value-of select="xs:date(substring($Effective_Moment, 0, 11))" />
			</BEGDA>
			<!-- ==== Workers Address Line 1 ==== -->
			<STRAS xtt:fixedLength="30">
				<xsl:value-of select="concat($AddressLine1,' ',$AddressLine3)" />
			</STRAS>
			<!-- ==== Workers City ==== -->
			<ORT01 xtt:fixedLength="25">
				<xsl:value-of select="$City" />
			</ORT01>
			<!-- ==== Workers Postal Code ==== -->
			<PSTLZ xtt:fixedLength="10">
				<xsl:value-of select="$PostalCode" />
			</PSTLZ>
		</IT0006>
	</xsl:template>

	<!-- ==== INFOTYPE 0007 TEMPLATE ==== -->
	<xsl:template name="IT0007">
		<xsl:param name="Employee_ID" />
		<xsl:param name="ScheduledWeeklyHours" />
		<xsl:param name="Effective_Moment" select="peci:Effective_Moment" />

		<IT0007 xtt:endTag="&#xd;&#xa;">
			<!-- ==== Workers Employee Id ==== -->
			<PERNR xtt:fixedLength="8">
				<xsl:value-of select="$Employee_ID" />
			</PERNR>
			<!-- ==== Hardcoded 0007 ==== -->
			<INFTY xtt:fixedLength="4">
				<xsl:value-of select="'0007'" />
			</INFTY>
			<!-- ==== BLANK ==== -->
			<BLANK xtt:fixedLength="4">
				<xsl:value-of select="''" />
			</BLANK>
			<!-- ==== Effective Moment ==== -->
			<BEGDA xtt:fixedLength="8" xtt:dateFormat="yyyyMMdd">
				<xsl:value-of select="xs:date(substring($Effective_Moment, 0, 11))" />
			</BEGDA>
			<!-- ==== Workers Scheduled Weekly Hours ==== -->
			<WOSTD xtt:fixedLength="7" xtt:align="right">
				<xsl:value-of select="$ScheduledWeeklyHours" />
			</WOSTD>
		</IT0007>
	</xsl:template>

	<!-- ==== INFOTYPE 0008 TEMPLATE ==== -->
	<xsl:template name="IT0008">
		<xsl:param name="Employee_ID" />
		<xsl:param name="Staffing_Event" />
		<xsl:param name="PayScaleType" />
		<xsl:param name="PayScaleLevel" />
		<xsl:param name="CompChangeReason" />
		<xsl:param name="HireDate" />
		<xsl:param name="EffectiveDate" />

		<!-- === Exclude records where only an end date has been added for the 
			Salary Plan === -->
		<xsl:variable name="SalaryValueCar">
			<xsl:value-of select="0" />
			<xsl:for-each
				select="peci:Compensation_Earnings_and_Deductions[contains(peci:External_Payroll_Code, 'IT008_125')]">
				<xsl:value-of select="peci:Amount" />
			</xsl:for-each>
		</xsl:variable>
		<!-- ==== 15.01.2019 - Get current Salary Value for Housing === -->
		<xsl:variable name="SalaryValueHousing">
			<xsl:value-of select="0" />
			<xsl:for-each
				select="peci:Compensation_Earnings_and_Deductions[contains(peci:External_Payroll_Code, 'IT008_127')]">
				<xsl:value-of select="peci:Amount" />
			</xsl:for-each>
		</xsl:variable>
		<!-- ==== 15.01.2019 - Mettova need to include current i.e. unchanged values 
			if salary change === -->
		<xsl:variable name="SalaryisUpdated" as="xs:boolean">
			<xsl:choose>
				<xsl:when
					test="(count(peci:Compensation_Earnings_and_Deductions[@peci:isAdded = '1' or @peci:isUpdated = '1'][contains(peci:External_Payroll_Code, 'IT008_110')])
                                + count(peci:Compensation_Plans/peci:Salary_and_Hourly_Plan[@peci:isAdded = '1' or @peci:isUpdated = '1']) >= 1)">
					<xsl:value-of select="true()" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="false()" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!-- ==== 15.01.2019 - Mettova need to include current i.e. unchanged values 
			if percentage changes === -->
		<xsl:variable name="PercentageisUpdated" as="xs:boolean">
			<xsl:choose>
				<xsl:when
					test="(count(peci:Compensation_Earnings_and_Deductions[@peci:isAdded = '1' or @peci:isUpdated = '1'][contains(peci:External_Payroll_Code, 'IT008_101')]) >= 1)">
					<xsl:value-of select="true()" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="false()" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="PercentageisDeleted" as="xs:boolean">
			<!-- <xsl:value-of select="count(peci:Compensation_Plans/peci:Allowance_Plan[contains(peci:Compensation_Plan, 
				'IT008_101')])"/> -->
			<xsl:choose>
				<xsl:when
					test="(count(peci:Compensation_Plans/peci:Allowance_Plan[contains(peci:Compensation_Plan, 'IT008_101')]) = 1)">
					<xsl:value-of select="true()" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="false()" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!-- ==== 15.01.2019 - Mettova need to include current i.e. unchanged values 
			if percentage changes === -->
		<xsl:variable name="StepAmountChanged" as="xs:boolean">
			<xsl:choose>
				<xsl:when
					test="peci:elementChanged(peci:Additional_Information/ptdf:Step_Amount) = ('CH1', 'CHA', 'CHP')
								     and peci:elementChanged(peci:Additional_Information/ptdf:Step_Amount) != '0'">
					<xsl:value-of select="true()" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="false()" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="IsHourlyPaid">
			<xsl:choose>
				<xsl:when
					test="peci:Additional_Information/ptdf:Pay_Rate_Type/ptdf:Pay_Rate_Type_ID = 'Hourly'">
					<xsl:value-of select="true()" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="false()" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="EndDateOnly" as="xs:boolean">
			<xsl:choose>
				<xsl:when test="$Staffing_Event = 'G1'">
					<xsl:value-of select="false()" />
				</xsl:when>
				<xsl:when test="$PercentageisUpdated = true()">
					<xsl:value-of select="false()" />
				</xsl:when>
				<xsl:when
					test="(count(peci:Compensation_Plans/peci:Salary_and_Hourly_Plan[(peci:End_Date[@peci:isAdded = '1'])][contains(peci:Compensation_Plan,'KONE_Salary_Plan') or contains(peci:Compensation_Plan,'Hourly_Plan') or contains(peci:Compensation_Plan,'HOURLY_PLAN')])
	       					+ count(peci:Compensation_Plans/peci:Salary_and_Hourly_Plan[@peci:isAdded = '1' or @peci:isUpdated = '1'][not(peci:End_Date[@peci:isAdded = '1'])][contains(peci:Compensation_Plan,'KONE_Salary_Plan') or contains(peci:Compensation_Plan,'Hourly_Plan') or contains(peci:Compensation_Plan,'HOURLY_PLAN')]) 
	       					+ count(peci:Compensation_Plans[@peci:isAdded='1']/peci:Salary_and_Hourly_Plan[not(peci:End_Date[@peci:isAdded = '1'])][contains(peci:Compensation_Plan,'KONE_Salary_Plan')])
		   					+ count(peci:Compensation_Earnings_and_Deductions[@peci:isAdded = '1' or @peci:isUpdated = '1'][contains(peci:External_Payroll_Code,'IT008_110')]) &lt;= 1)">
					<xsl:value-of select="true()" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="false()" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:choose>
			<xsl:when test="$EndDateOnly = false()">

				<IT0008 xtt:endTag="&#xd;&#xa;">
					<!-- ==== Workers Employee Id ==== -->
					<PERNR xtt:fixedLength="8">
						<xsl:value-of select="$Employee_ID" />
					</PERNR>
					<!-- ==== Hardcoded 0008 ==== -->
					<INFTY xtt:fixedLength="4">
						<xsl:value-of select="'0008'" />
					</INFTY>
					<!-- ==== BLANK ==== -->
					<BLANK xtt:fixedLength="4">
						<xsl:value-of select="''" />
					</BLANK>
					<!-- ==== If Effective Date is not empty then Effective Date ==== -->
					<!-- ==== Else Hire Date ==== -->
					<BEGDA xtt:fixedLength="8" xtt:dateFormat="yyyyMMdd">
						<xsl:choose>
							<xsl:when test="exists($EffectiveDate)">
								<xsl:value-of select="$EffectiveDate" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$HireDate" />
							</xsl:otherwise>
						</xsl:choose>
					</BEGDA>
					<!-- ==== If Staffing Event is G1 then 1 ==== -->
					<!-- ==== Else Compensation Change reason ==== -->
					<PREAS xtt:fixedLength="2">
						<xsl:choose>
							<xsl:when test="$Staffing_Event = 'G1'">
								<xsl:value-of select="'1'" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$CompChangeReason" />
							</xsl:otherwise>
						</xsl:choose>
					</PREAS>
					<!-- ==== If Collective Agreement Factor is Operative then OP ==== -->
					<!-- ==== If Pay Scalre Type is not empty then Pay Scale Type ==== -->
					<TRFAR xtt:fixedLength="2">
						<xsl:if
							test="peci:Additional_Information/ptdf:Collective_Agreement_Factor_1 = 'Operative'">
							<xsl:value-of select="'OP'" />
						</xsl:if>
						<xsl:if test="$PayScaleType">
							<xsl:value-of select="$PayScaleType" />
						</xsl:if>
					</TRFAR>
					<!-- ==== Collective Agreement Factor 3 Variable ==== -->
					<xsl:variable name="CA_Factor3">
						<xsl:value-of
							select="substring-after(peci:Additional_Information/ptdf:Collective_Agreement_Factor_3, 'Level_')" />
					</xsl:variable>
					<!-- ==== If Collective Agreement Factor is FIN_METTOVA then true ==== -->
					<!-- ==== If workers pay rate type is Salary then true ==== -->
					<xsl:variable name="WageTypeCheck1">
						<xsl:choose>
							<xsl:when
								test="../../peci:Additional_Information/ptdf:Collective_Agreement_Factor_2 = 'FIN_METTOVA'">
								<xsl:value-of select="'true'" />
							</xsl:when>
							<xsl:when
								test="../../peci:Position[not(@peci:isDeleted = '1')]/peci:Pay_Rate_Type = 'Salary'">
								<xsl:value-of select="'true'" />
							</xsl:when>
						</xsl:choose>
					</xsl:variable>
					<!-- ==== if a compensation external earnings and deductions (IT0008) 
						has a payroll code that contains 100, 101, 110, 911, 912 or 913) then true 
						==== -->
					<!-- ==== Else false ==== -->
					<xsl:variable name="WageTypeCheck2">
						<xsl:for-each
							select="peci:Compensation_Earnings_and_Deductions[contains(peci:External_Payroll_Code, 'IT008')]">
							<xsl:choose>
								<xsl:when test="contains(peci:External_Payroll_Code, ('100'))">
									<xsl:value-of select="'true'" />
								</xsl:when>
								<xsl:when test="contains(peci:External_Payroll_Code, ('101'))">
									<xsl:value-of select="'true'" />
								</xsl:when>
								<xsl:when test="contains(peci:External_Payroll_Code, ('110'))">
									<xsl:value-of select="'true'" />
								</xsl:when>
								<xsl:when test="contains(peci:External_Payroll_Code, ('911'))">
									<xsl:value-of select="'true'" />
								</xsl:when>
								<xsl:when test="contains(peci:External_Payroll_Code, ('912'))">
									<xsl:value-of select="'true'" />
								</xsl:when>
								<xsl:when test="contains(peci:External_Payroll_Code, ('913'))">
									<xsl:value-of select="'true'" />
								</xsl:when>
							</xsl:choose>
						</xsl:for-each>
					</xsl:variable>
					<!-- ==== if (collective agreement is FIN_PARAKE or FIN_METTOVA) and 
						(either of the Wage Type Check varisables are not blank) then... ==== -->
					<!-- ==== If Factor 3 string legnth is 1 then concatenate (0 + Factor 
						3)... Add a leading 0 to make this 2 digits ==== -->
					<!-- ==== Else Factor 3 ==== -->
					<TRFST xtt:fixedLength="2">
						<xsl:choose>
							<xsl:when
								test="peci:Additional_Information/ptdf:Collective_Agreement_Factor_2 = ('FIN_PARAKE', 'FIN_METTOVA') and ($WageTypeCheck1 != '' or $WageTypeCheck2 != '')">
								<xsl:value-of
									select="
                                if (string-length($CA_Factor3) = 1) then
                                    concat('0', $CA_Factor3)
                                else
                                    $CA_Factor3" />
							</xsl:when>
							<xsl:otherwise />
						</xsl:choose>
					</TRFST>
					<!-- ==== For each compensation plan, salary and hourly plan, call template 
						IT0008_WageTypeInfo === -->
					<!-- ==== 15.01.2019 - Get current Salary Value for Car === -->

					<!-- ==== For each compensation plan, salary and hourly plan, call template 
						IT0008_WageTypeInfo === -->
					<xsl:for-each
						select="peci:Compensation_Plans[@peci:isAdded = '1']/peci:Salary_and_Hourly_Plan">
						<!-- ==== If Collective Agreement Factor is FIN_METTOVA then 100 === -->
						<!-- ==== If Collective Agreement Factor is FIN_PARAKE then F === -->
						<!-- ==== If workers Pay Rate Type is Hourly then 914 === -->
						<!-- ==== If workers Pay Rate Type is Salary then 110 === -->
						<!-- ==== Else No value === -->
						<xsl:variable name="LGAXX">
							<xsl:choose>
								<!-- <xsl:when test="../../peci:Additional_Information/ptdf:Collective_Agreement_Factor_2 
									= 'FIN_METTOVA'"> <xsl:value-of select="'110'" /> </xsl:when> <xsl:when test="../../peci:Additional_Information/ptdf:Collective_Agreement_Factor_2 
									= 'FIN_PARAKE'"> <xsl:value-of select="'914'" /> </xsl:when> -->
								<xsl:when test="peci:Compensation_Plan = 'Finland_Hourly_Plan_216'">
									<xsl:value-of select="'914'" />
								</xsl:when>
								<xsl:when test="peci:Compensation_Plan = 'Finland_Hourly_Plan_217'">
									<xsl:value-of select="'915'" />
								</xsl:when>
								<xsl:when
									test="../../peci:Position[not(@peci:isDeleted = '1')]/peci:Pay_Rate_Type = 'Hourly'">
									<xsl:value-of select="'901'" />
								</xsl:when>
								<xsl:when
									test="../../peci:Position[not(@peci:isDeleted = '1')]/peci:Pay_Rate_Type = 'Salary'">
									<xsl:value-of select="'110'" />
								</xsl:when>
							</xsl:choose>
						</xsl:variable>
						<!-- ==== If frequency is Annual then divide amount by 12 === -->
						<!-- ==== Else Amount === -->
						<!-- ==== Use Prorated amount for salary value if it exists to handle 
							part time salaries === -->
						<!-- ==== 15.01.2019 - If employee in staff or management collective 
							agreement then salary amount is salary minus salary value for car and housing -->
						<xsl:variable name="BETXX">
							<xsl:choose>
								<xsl:when
									test="contains(../peci:Additional_Information/ptdf:Collective_Agreement/ptdf:Collective_Agreement_ID, 'Staff') or contains(../peci:Additional_Information/ptdf:Collective_Agreement/ptdf:Collective_Agreement_ID, 'management') or contains(../peci:Additional_Information/ptdf:Collective_Agreement/ptdf:Collective_Agreement_ID, 'Metal')">
									<xsl:choose>
										<xsl:when test="peci:Compensation_Plan = 'KONE_Salary_Plan'">
											<xsl:choose>
												<xsl:when
													test="peci:Frequency = 'Annual' and peci:Prorated_Amount != ''">
													<xsl:value-of
														select="peci:Prorated_Amount div 12 - $SalaryValueCar - $SalaryValueHousing" />
												</xsl:when>
												<xsl:when test="peci:Frequency = 'Finland_Hourly_Frequency'">
													<xsl:value-of select="peci:Amount" />
												</xsl:when>
												<xsl:when test="peci:Prorated_Amount != ''">
													<xsl:value-of
														select="peci:Prorated_Amount - $SalaryValueCar - $SalaryValueHousing" />
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of
														select="peci:Amount - $SalaryValueCar - $SalaryValueHousing" />
												</xsl:otherwise>
											</xsl:choose>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="peci:Amount" />
										</xsl:otherwise>
									</xsl:choose>
								</xsl:when>
								<xsl:otherwise>
									<xsl:choose>
										<xsl:when test="peci:Compensation_Plan = 'KONE_Salary_Plan'">
											<xsl:choose>
												<xsl:when
													test="peci:Frequency = 'Annual' and peci:Prorated_Amount != ''">
													<xsl:value-of
														select="peci:Prorated_Amount div 12 - $SalaryValueCar - $SalaryValueHousing" />
												</xsl:when>
												<xsl:when test="peci:Frequency = 'Finland_Hourly_Frequency'">
													<xsl:value-of select="peci:Amount" />
												</xsl:when>
												<xsl:when test="peci:Prorated_Amount != ''">
													<xsl:value-of
														select="peci:Prorated_Amount - $SalaryValueCar - $SalaryValueHousing" />
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of
														select="peci:Amount - $SalaryValueCar - $SalaryValueHousing" />
												</xsl:otherwise>
											</xsl:choose>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="peci:Amount" />
										</xsl:otherwise>
									</xsl:choose>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<xsl:call-template name="IT0008_WageTypeInfo">
							<xsl:with-param name="LGAXX" select="$LGAXX" />
							<xsl:with-param name="BETXX" select="$BETXX" />
							<xsl:with-param name="counter" select="position()" />
						</xsl:call-template>
					</xsl:for-each>
					<!-- ==== For each compensation plan, salary and hourly plan - where 
						there is no end date, call template IT0008_WageTypeInfo === -->
					<xsl:for-each
						select="peci:Compensation_Plans[@peci:isUpdated = '1']/peci:Salary_and_Hourly_Plan[@peci:isAdded = '1' or @peci:isUpdated = '1'][not(peci:End_Date[@peci:isAdded = '1'])]">
						<!-- ==== If Collective Agreement Factor is FIN_METTOVA then 100 === -->
						<!-- ==== If Collective Agreement Factor is FIN_PARAKE then 914 === -->
						<!-- ==== If workers Pay Rate Type is Hourly then 914 === -->
						<!-- ==== If workers Pay Rate Type is Salary then 110 === -->
						<!-- ==== Else No value === -->
						<xsl:variable name="LGAXX">
							<xsl:choose>
								<!-- <xsl:when test="../../peci:Additional_Information/ptdf:Collective_Agreement_Factor_2 
									= 'FIN_METTOVA'"> <xsl:value-of select="'110'" /> </xsl:when> <xsl:when test="../../peci:Additional_Information/ptdf:Collective_Agreement_Factor_2 
									= 'FIN_PARAKE'"> <xsl:value-of select="'914'" /> </xsl:when> -->
								<xsl:when test="peci:Compensation_Plan = 'Finland_Hourly_Plan_216'">
									<xsl:value-of select="'914'" />
								</xsl:when>
								<xsl:when test="peci:Compensation_Plan = 'Finland_Hourly_Plan_217'">
									<xsl:value-of select="'915'" />
								</xsl:when>
								<xsl:when
									test="../../peci:Position[not(@peci:isDeleted = '1')]/peci:Pay_Rate_Type = 'Hourly'">
									<xsl:value-of select="'901'" />
								</xsl:when>
								<xsl:when
									test="../../peci:Position[not(@peci:isDeleted = '1')]/peci:Pay_Rate_Type = 'Salary'">
									<xsl:value-of select="'110'" />
								</xsl:when>
							</xsl:choose>
						</xsl:variable>
						<!-- ==== If frequency is Annual then divide amount by 12 === -->
						<!-- ==== Else Amount === -->
						<!-- ==== Use Prorated amount for salary value if it exists to handle 
							part time salaries === -->
						<!-- ==== 15.01.2019 - If employee in staff or management collective 
							or Mettova agreement then salary amount is salary minus salary value for 
							car and housing -->
						<xsl:variable name="BETXX">
							<xsl:choose>
								<xsl:when
									test="contains(../peci:Additional_Information/ptdf:Collective_Agreement/ptdf:Collective_Agreement_ID, 'Staff') or contains(../peci:Additional_Information/ptdf:Collective_Agreement/ptdf:Collective_Agreement_ID, 'management') or contains(../peci:Additional_Information/ptdf:Collective_Agreement/ptdf:Collective_Agreement_ID, 'Metal')">
									<xsl:choose>
										<xsl:when test="peci:Compensation_Plan = 'KONE_Salary_Plan'">
											<xsl:choose>
												<xsl:when
													test="peci:Frequency = 'Annual' and peci:Prorated_Amount != ''">
													<xsl:value-of
														select="peci:Prorated_Amount div 12 - $SalaryValueCar - $SalaryValueHousing" />
												</xsl:when>
												<xsl:when test="peci:Frequency = 'Finland_Hourly_Frequency'">
													<xsl:value-of select="peci:Amount" />
												</xsl:when>
												<xsl:when test="peci:Prorated_Amount != ''">
													<xsl:value-of
														select="peci:Prorated_Amount - $SalaryValueCar - $SalaryValueHousing" />
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of
														select="peci:Amount - $SalaryValueCar - $SalaryValueHousing" />
												</xsl:otherwise>
											</xsl:choose>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="peci:Amount" />
										</xsl:otherwise>
									</xsl:choose>
								</xsl:when>
								<xsl:otherwise>
									<xsl:choose>
										<xsl:when test="peci:Compensation_Plan = 'KONE_Salary_Plan'">
											<xsl:choose>
												<xsl:when
													test="peci:Frequency = 'Annual' and peci:Prorated_Amount != ''">
													<xsl:value-of
														select="peci:Prorated_Amount div 12 - $SalaryValueCar - $SalaryValueHousing" />
												</xsl:when>
												<xsl:when test="peci:Frequency = 'Finland_Hourly_Frequency'">
													<xsl:value-of select="peci:Amount" />
												</xsl:when>
												<xsl:when test="peci:Prorated_Amount != ''">
													<xsl:value-of
														select="peci:Prorated_Amount - $SalaryValueCar - $SalaryValueHousing" />
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of
														select="peci:Amount - $SalaryValueCar - $SalaryValueHousing" />
												</xsl:otherwise>
											</xsl:choose>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="peci:Amount" />
										</xsl:otherwise>
									</xsl:choose>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<xsl:call-template name="IT0008_WageTypeInfo">
							<xsl:with-param name="LGAXX" select="$LGAXX" />
							<xsl:with-param name="BETXX" select="$BETXX" />
							<xsl:with-param name="counter" select="position()" />
						</xsl:call-template>
					</xsl:for-each>
					<!-- ==== 21.01.2019 New section to add WT110 if salary unchanged but 
						=== -->
					<!-- ==== either the percentage or step have changed === -->
					<xsl:choose>
						<xsl:when
							test="$SalaryisUpdated = false() and ($PercentageisUpdated = true()) ">
							<!-- test="$SalaryisUpdated = false() and ($PercentageisUpdated = 
								true() or $StepAmountChanged = true()) "> -->
							<!-- test="contains(peci:Additional_Information/ptdf:Collective_Agreement/ptdf:Collective_Agreement_ID, -->
							<!-- 'Metal')"> -->
							<xsl:for-each
								select="peci:Compensation_Plans/peci:Salary_and_Hourly_Plan[not(@peci:isDeleted = '1')]">
								<xsl:variable name="LGAXX">
									<xsl:choose>
										<!-- <xsl:when test="../../peci:Additional_Information/ptdf:Collective_Agreement_Factor_2 
											= 'FIN_METTOVA'"> <xsl:value-of select="'110'" /> </xsl:when> <xsl:when test="../../peci:Additional_Information/ptdf:Collective_Agreement_Factor_2 
											= 'FIN_PARAKE'"> <xsl:value-of select="'914'" /> </xsl:when> -->
										<xsl:when test="peci:Compensation_Plan = 'Finland_Hourly_Plan_216'">
											<xsl:value-of select="'914'" />
										</xsl:when>
										<xsl:when test="peci:Compensation_Plan = 'Finland_Hourly_Plan_217'">
											<xsl:value-of select="'915'" />
										</xsl:when>
										<xsl:when
											test="../../peci:Position[not(@peci:isDeleted = '1')]/peci:Pay_Rate_Type = 'Hourly'">
											<xsl:value-of select="'901'" />
										</xsl:when>
										<xsl:when
											test="../../peci:Position[not(@peci:isDeleted = '1')]/peci:Pay_Rate_Type = 'Salary'">
											<xsl:value-of select="'110'" />
										</xsl:when>
									</xsl:choose>
								</xsl:variable>
								<!-- ==== If frequency is Annual then divide amount by 12 === ==== 
									Else Amount === ==== Use Prorated amount for salary value if it exists to 
									handle part time salaries === ==== 15.01.2019 - If employee in staff or management 
									collective agreement then salary amount is salary minus salary value for 
									car and housing -->
								<xsl:variable name="BETXX">
									<xsl:choose>
										<xsl:when
											test="contains(../peci:Additional_Information/ptdf:Collective_Agreement/ptdf:Collective_Agreement_ID, 'Staff') or contains(../peci:Additional_Information/ptdf:Collective_Agreement/ptdf:Collective_Agreement_ID, 'management') or contains(../peci:Additional_Information/ptdf:Collective_Agreement/ptdf:Collective_Agreement_ID, 'Metal')">
											<xsl:choose>
												<xsl:when test="peci:Compensation_Plan = 'KONE_Salary_Plan'">
													<xsl:choose>
														<xsl:when
															test="peci:Frequency = 'Annual' and peci:Prorated_Amount != ''">
															<xsl:value-of
																select="peci:Prorated_Amount div 12 - $SalaryValueCar - $SalaryValueHousing" />
														</xsl:when>
														<xsl:when test="peci:Frequency = 'Finland_Hourly_Frequency'">
															<xsl:value-of select="peci:Amount" />
														</xsl:when>
														<xsl:when test="peci:Prorated_Amount != ''">
															<xsl:value-of
																select="peci:Prorated_Amount - $SalaryValueCar - $SalaryValueHousing" />
														</xsl:when>
														<xsl:otherwise>
															<xsl:value-of
																select="peci:Amount - $SalaryValueCar - $SalaryValueHousing" />
														</xsl:otherwise>
													</xsl:choose>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="peci:Amount" />
												</xsl:otherwise>
											</xsl:choose>
										</xsl:when>
										<xsl:otherwise>
											<xsl:choose>
												<xsl:when test="peci:Compensation_Plan = 'KONE_Salary_Plan'">
													<xsl:choose>
														<xsl:when
															test="peci:Frequency = 'Annual' and peci:Prorated_Amount != ''">
															<xsl:value-of
																select="peci:Prorated_Amount div 12 - $SalaryValueCar - $SalaryValueHousing" />
														</xsl:when>
														<xsl:when test="peci:Frequency = 'Finland_Hourly_Frequency'">
															<xsl:value-of select="peci:Amount" />
														</xsl:when>
														<xsl:when test="peci:Prorated_Amount != ''">
															<xsl:value-of
																select="peci:Prorated_Amount - $SalaryValueCar - $SalaryValueHousing" />
														</xsl:when>
														<xsl:otherwise>
															<xsl:value-of
																select="peci:Amount - $SalaryValueCar - $SalaryValueHousing" />
														</xsl:otherwise>
													</xsl:choose>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="peci:Amount" />
												</xsl:otherwise>
											</xsl:choose>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								<xsl:call-template name="IT0008_WageTypeInfo">
									<xsl:with-param name="LGAXX" select="$LGAXX" />
									<xsl:with-param name="BETXX" select="$BETXX" />
									<xsl:with-param name="counter" select="position()" />
								</xsl:call-template>
							</xsl:for-each>
						</xsl:when>
					</xsl:choose>
					<!-- ==== 21.01.2019 New section to add WT100 based on Step_Amount change=== -->
					<!-- ==== Need to add this if there is a change in step value or a salary 
						change === -->
					<xsl:choose>
						<xsl:when
							test="peci:Additional_Information/ptdf:Step_Amount > '0' and $IsHourlyPaid = false() and ($StepAmountChanged = true() or $SalaryisUpdated = true() or $PercentageisUpdated = true())">
							<xsl:variable name="LGAXX">
								<xsl:value-of select="100" />
							</xsl:variable>
							<xsl:variable name="BETXX">
								<xsl:value-of select="peci:Additional_Information/ptdf:Step_Amount" />
							</xsl:variable>
							<xsl:call-template name="IT0008_WageTypeInfo">
								<xsl:with-param name="LGAXX" select="$LGAXX" />
								<xsl:with-param name="BETXX" select="$BETXX" />
								<xsl:with-param name="counter" select="1" />
							</xsl:call-template>
						</xsl:when>
					</xsl:choose>
					<!-- ==== 21.01.2019 New section to calculate Mettova Personal Skills 
						from step value based on plan percentage === -->
					<xsl:for-each
						select="peci:Compensation_Plans/peci:Allowance_Plan[contains(peci:Compensation_Plan, 'IT008_101')][not(@peci:isDeleted = '1')]">
						<!-- select="peci:Compensation_Plans[@peci:isUpdated = '1']/peci:Allowance_Plan[@peci:isAdded 
							= '1' or @peci:isUpdated = '1'][contains(peci:Compensation_Plan, 'IT008_101')]"> -->
						<xsl:choose>
							<xsl:when
								test="$SalaryisUpdated = true() or $PercentageisUpdated = true()">
								<!-- test="$SalaryisUpdated = true() or PercentageisUpdated = true() 
									and contains(../../peci:Additional_Information/ptdf:Collective_Agreement/ptdf:Collective_Agreement_ID, 
									'Metal') "> -->
								<xsl:choose>
									<!-- <xsl:when test="peci:End_Date[@peci:isAdded = 1] and $PercentageisDeleted 
										= false()"> -->
									<xsl:when
										test="peci:End_Date[@peci:isAdded = 1] and $PercentageisDeleted = true()">
										<!-- === Send zero percentage if allowance has been deleted and 
											no new allowance added === -->
										<xsl:variable name="LGAXX">
											<xsl:value-of
												select="translate(substring-after(peci:Compensation_Plan, 'IT008_'), 'abcdefghijklmnopqrstuvqxyz', '')" />
										</xsl:variable>
										<xsl:variable name="BETXX">
											<xsl:value-of select="0.00" />
										</xsl:variable>
										<xsl:call-template name="IT0008_WageTypeInfo">
											<xsl:with-param name="LGAXX" select="$LGAXX" />
											<xsl:with-param name="BETXX" select="$BETXX" />
											<xsl:with-param name="counter" select="1" />
										</xsl:call-template>
									</xsl:when>
									<xsl:when test="peci:End_Date[@peci:isAdded = 1]">
										<!-- === Don't send anything for ended entries as in this case 
											will be a new entry for wage type === -->
									</xsl:when>
									<xsl:otherwise>
										<xsl:variable name="LGAXX">
											<xsl:value-of
												select="translate(substring-after(peci:Compensation_Plan, 'IT008_'), 'abcdefghijklmnopqrstuvqxyz', '')" />
											<!-- select="$PercentageisDeleted" /> -->
										</xsl:variable>
										<xsl:variable name="BETXX">
											<xsl:value-of select="peci:Percentage * 100" />
										</xsl:variable>
										<xsl:call-template name="IT0008_WageTypeInfo">
											<xsl:with-param name="LGAXX" select="$LGAXX" />
											<xsl:with-param name="BETXX" select="$BETXX" />
											<xsl:with-param name="counter" select="1" />
										</xsl:call-template>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:when>
						</xsl:choose>
					</xsl:for-each>
					<!-- ==== 21.01.2019 This section now only handles the Mettova / Personal 
						Part === -->
					<xsl:for-each
						select="peci:Compensation_Earnings_and_Deductions[@peci:isAdded = '1' or @peci:isUpdated = '1'][contains(peci:External_Payroll_Code, 'IT008_102')]">
						<!-- ==== External Payroll Code. Letters removed and text after IT008_ 
							=== -->
						<!-- <xsl:choose> -->
						<!-- <xsl:when -->
						<!-- test="contains(../../peci:Additional_Information/ptdf:Collective_Agreement/ptdf:Collective_Agreement_ID, 
							'Metal')"> -->
						<xsl:variable name="LGAXX">
							<xsl:value-of
								select="translate(substring-after(peci:External_Payroll_Code, 'IT008_'), 'abcdefghijklmnopqrstuvqxyz', '')" />
						</xsl:variable>
						<!-- ==== If frequency is Annual then divide amount by 12 === -->
						<!-- ==== Else Amount === -->
						<xsl:variable name="BETXX">
							<xsl:choose>
								<xsl:when test="peci:Frequency = 'Annual'">
									<xsl:value-of select="peci:Amount div 12" />
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="peci:Amount" />
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<xsl:choose>
							<!-- === Salary Plans excluded otherwise these are duplicated in the 
								output as handle in previous steps === -->
							<xsl:when
								test="$LGAXX != '100' and $LGAXX != '110' and $LGAXX !='914'">
								<xsl:call-template name="IT0008_WageTypeInfo">
									<xsl:with-param name="LGAXX" select="$LGAXX" />
									<xsl:with-param name="BETXX" select="$BETXX" />
									<xsl:with-param name="counter" select="position()" />
								</xsl:call-template>
							</xsl:when>
						</xsl:choose>
						<!-- </xsl:when> -->
						<!-- </xsl:choose> -->
					</xsl:for-each>
				</IT0008>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<!-- ==== INFOTYPE 0008 WAGE TYPE TEMPLATE ==== -->
	<xsl:template name="IT0008_WageTypeInfo">
		<xsl:param name="LGAXX" />
		<xsl:param name="BETXX" />
		<xsl:param name="counter" />

		<xsl:choose>
			<xsl:when test="$counter = 1">
				<LGAXX xtt:fixedLength="4">
					<xsl:value-of select="$LGAXX" />
				</LGAXX>
				<BETXX xtt:fixedLength="14" xtt:align="right"
					xtt:numberFormat="#.00">
					<xsl:value-of select="$BETXX" />
				</BETXX>
				<ANZXX xtt:fixedLength="9" />
			</xsl:when>
			<xsl:otherwise>
				<LGAXX xtt:fixedLength="5">
					<xsl:value-of select="$LGAXX" />
				</LGAXX>
				<BETXX xtt:fixedLength="15" xtt:align="right"
					xtt:numberFormat="#.00">
					<xsl:value-of select="$BETXX" />
				</BETXX>
				<ANZXX xtt:fixedLength="10" />
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>

	<!-- ==== INFOTYPE 0009 TEMPLATE ==== -->
	<xsl:template name="IT0009">
		<xsl:param name="Employee_ID" />
		<xsl:param name="IBAN" />
		<xsl:param name="Effective_Moment" select="../peci:Effective_Moment" />

		<IT0009 xtt:endTag="&#xd;&#xa;">
			<!-- ==== Workers Employee Id ==== -->
			<PERNR xtt:fixedLength="8">
				<xsl:value-of select="$Employee_ID" />
			</PERNR>
			<!-- ==== Hardcoded 0009 ==== -->
			<INFTY xtt:fixedLength="4">
				<xsl:value-of select="'0009'" />
			</INFTY>
			<!-- ==== BLANK ==== -->
			<BLANK xtt:fixedLength="4">
				<xsl:value-of select="''" />
			</BLANK>
			<!-- ==== Effective Moment ==== -->
			<BEGDA xtt:fixedLength="8" xtt:dateFormat="yyyyMMdd">
				<xsl:value-of select="xs:date(substring($Effective_Moment, 0, 11))" />
			</BEGDA>
			<!-- ==== Workers IBAN ==== -->
			<IBAN xtt:fixedLength="34">
				<xsl:value-of select="$IBAN" />
			</IBAN>
		</IT0009>
	</xsl:template>

	<!-- ==== INFOTYPE 0014 TEMPLATE ==== -->
	<xsl:template name="IT0014">
		<xsl:param name="Employee_ID" />
		<xsl:param name="ExternalPayrollCode" />
		<xsl:param name="ExternalPayrollAmount" />

		<xsl:variable name="BEGDA">
			<xsl:choose>
				<xsl:when
					test="(../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[@peci:isAdded = '1'][peci:Compensation_Plan = $ExternalPayrollCode and peci:Amount = $ExternalPayrollAmount])[last()]/peci:Start_Date">
					<xsl:value-of
						select="(../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[@peci:isAdded = '1'][peci:Compensation_Plan = $ExternalPayrollCode  and peci:Amount = $ExternalPayrollAmount])[last()]/peci:Start_Date" />
				</xsl:when>
				<xsl:when
					test="(../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[@peci:isUpdated = '1'][peci:Compensation_Plan = $ExternalPayrollCode and peci:Amount = $ExternalPayrollAmount])[last()]/peci:Start_Date">
					<xsl:value-of
						select="(../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[@peci:isUpdated = '1'][peci:Compensation_Plan = $ExternalPayrollCode  and peci:Amount = $ExternalPayrollAmount])[last()]/peci:Start_Date" />
				</xsl:when>
				<xsl:when
					test="(../../peci:Effective_Change/peci:Compensation_Plans[@peci:isAdded = '1']/peci:Allowance_Plan[peci:Compensation_Plan = $ExternalPayrollCode and peci:Amount = $ExternalPayrollAmount])[last()]/peci:Start_Date">
					<xsl:value-of
						select="(../../peci:Effective_Change/peci:Compensation_Plans[@peci:isAdded = '1']/peci:Allowance_Plan[peci:Compensation_Plan = $ExternalPayrollCode  and peci:Amount = $ExternalPayrollAmount])[last()]/peci:Start_Date" />
				</xsl:when>
				<xsl:when
					test="(../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[peci:Compensation_Plan = $ExternalPayrollCode and peci:Amount = $ExternalPayrollAmount/@peci:priorValue])[last()]/peci:Start_Date">
					<xsl:value-of
						select="(../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[peci:Compensation_Plan = $ExternalPayrollCode  and peci:Amount = $ExternalPayrollAmount/@peci:priorValue])[last()]/peci:Start_Date" />
				</xsl:when>
				<xsl:otherwise />
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="ENDDA">
			<xsl:choose>
				<xsl:when
					test="((../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[@peci:isAdded = '1'][peci:Compensation_Plan = $ExternalPayrollCode and peci:Amount = $ExternalPayrollAmount])[last()]/peci:Start_Date = $BEGDA) and ((../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[@peci:isAdded = '1'][peci:Compensation_Plan = $ExternalPayrollCode and peci:Amount = $ExternalPayrollAmount])[last()]/peci:End_Date)">
					<xsl:value-of
						select="xs:date(substring((../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[@peci:isAdded = '1'][peci:Compensation_Plan = $ExternalPayrollCode  and peci:Amount = $ExternalPayrollAmount])[last()]/peci:End_Date, 0, 11))" />
				</xsl:when>
				<xsl:when
					test="((../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[@peci:isUpdated = '1'][peci:Compensation_Plan = $ExternalPayrollCode and peci:Amount = $ExternalPayrollAmount])[last()]/peci:Start_Date = $BEGDA) and ((../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[@peci:isUpdated = '1'][peci:Compensation_Plan = $ExternalPayrollCode and peci:Amount = $ExternalPayrollAmount])[last()]/peci:End_Date)">
					<xsl:value-of
						select="xs:date(substring((../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[@peci:isUpdated = '1'][peci:Compensation_Plan = $ExternalPayrollCode  and peci:Amount = $ExternalPayrollAmount])[last()]/peci:End_Date, 0, 11))" />
				</xsl:when>
				<xsl:when
					test="((../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[peci:Compensation_Plan = $ExternalPayrollCode and peci:Amount = $ExternalPayrollAmount])[last()]/peci:Start_Date = $BEGDA) and ((../../peci:Effective_Change/peci:Compensation_Plans[@peci:isAdded = '1']/peci:Allowance_Plan[peci:Compensation_Plan = $ExternalPayrollCode and peci:Amount = $ExternalPayrollAmount])[last()]/peci:End_Date)">
					<xsl:value-of
						select="(../../peci:Effective_Change/peci:Compensation_Plans[@peci:isAdded = '1']/peci:Allowance_Plan[peci:Compensation_Plan = $ExternalPayrollCode  and peci:Amount = $ExternalPayrollAmount])[last()]/peci:End_Date" />
				</xsl:when>
				<xsl:when
					test="((../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[peci:Compensation_Plan = $ExternalPayrollCode and peci:Amount = $ExternalPayrollAmount/@peci:priorValue])[last()]/peci:Start_Date = $BEGDA) and ((../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[peci:Compensation_Plan = $ExternalPayrollCode and peci:Amount = $ExternalPayrollAmount/@peci:priorValue])[last()]/peci:End_Date)">
					<xsl:value-of
						select="xs:date(substring((../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[peci:Compensation_Plan = $ExternalPayrollCode  and peci:Amount = $ExternalPayrollAmount/@peci:priorValue])[last()]/peci:End_Date, 0, 11))" />
				</xsl:when>
				<xsl:otherwise />
			</xsl:choose>
		</xsl:variable>

		<IT0014 xtt:endTag="&#xd;&#xa;">
			<!-- ==== Workers Employee Id ==== -->
			<PERNR xtt:fixedLength="8">
				<xsl:value-of select="$Employee_ID" />
			</PERNR>
			<!-- ==== Hardcoded 0014 ==== -->
			<INFTY xtt:fixedLength="4">
				<xsl:value-of select="'0014'" />
			</INFTY>
			<!-- ==== BLANK ==== -->
			<BLANK xtt:fixedLength="4">
				<xsl:value-of select="''" />
			</BLANK>
			<!-- ==== ENDDA Variable Parsed ==== -->
			<ENDDA xtt:fixedLength="8" xtt:dateFormat="yyyyMMdd">
				<xsl:value-of select="$ENDDA" />
			</ENDDA>
			<!-- ==== BEGDA Variable Parsed ==== -->
			<BEGDA xtt:fixedLength="8" xtt:dateFormat="yyyyMMdd">
				<xsl:choose>
					<xsl:when test="$BEGDA != ''">
						<xsl:value-of select="xs:date(substring($BEGDA, 0, 11))" />
					</xsl:when>
					<xsl:otherwise />
				</xsl:choose>
			</BEGDA>
			<!-- ==== External Payroll Code Parsed ==== -->
			<LGART xtt:fixedLength="4">
				<xsl:value-of
					select="translate(substring-after($ExternalPayrollCode, 'IT0014_'), 'abcdefghijklmnopqrstuvqxyz', '')" />
			</LGART>
			<!-- ==== Match the correct instance of the allowance plan and take the 
				amount ==== -->
			<BETRG xtt:fixedLength="14" xtt:align="right" xtt:numberFormat="#.00">
				<xsl:choose>
					<xsl:when
						test="((../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[@peci:isAdded = '1'][peci:Compensation_Plan = $ExternalPayrollCode and peci:Amount = $ExternalPayrollAmount])[last()]/peci:Start_Date = $BEGDA) and ((../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[@peci:isAdded = '1'][peci:Compensation_Plan = $ExternalPayrollCode and peci:Amount = $ExternalPayrollAmount])[last()]/peci:Amount)">
						<xsl:value-of
							select="(../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[@peci:isAdded = '1'][peci:Compensation_Plan = $ExternalPayrollCode  and peci:Amount = $ExternalPayrollAmount])[last()]/peci:Amount" />
					</xsl:when>
					<xsl:when
						test="((../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[@peci:isUpdated = '1'][peci:Compensation_Plan = $ExternalPayrollCode and peci:Amount = $ExternalPayrollAmount])[last()]/peci:Start_Date = $BEGDA) and ((../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[@peci:isUpdated = '1'][peci:Compensation_Plan = $ExternalPayrollCode and peci:Amount = $ExternalPayrollAmount])[last()]/peci:Amount)">
						<xsl:value-of
							select="(../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[@peci:isUpdated = '1'][peci:Compensation_Plan = $ExternalPayrollCode  and peci:Amount = $ExternalPayrollAmount])[last()]/peci:Amount" />
					</xsl:when>
					<xsl:when
						test="((../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[peci:Compensation_Plan = $ExternalPayrollCode and peci:Amount = $ExternalPayrollAmount/@peci:priorValue])[last()]/peci:Start_Date = $BEGDA) and ((../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[peci:Compensation_Plan = $ExternalPayrollCode and peci:Amount = $ExternalPayrollAmount/@peci:priorValue])[last()]/peci:Amount)">
						<xsl:value-of
							select="(../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[peci:Compensation_Plan = $ExternalPayrollCode  and peci:Amount = $ExternalPayrollAmount/@peci:priorValue])[last()]/peci:Amount" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="peci:Amount" />
					</xsl:otherwise>
				</xsl:choose>
			</BETRG>
			<!-- ==== Match the correct instance of the allowance plan and take the 
				number of units ==== -->
			<ANZHL xtt:fixedLength="9" xtt:align="right" xtt:numberFormat="#.00">
				<xsl:choose>
					<xsl:when
						test="((../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[@peci:isAdded = '1'][peci:Compensation_Plan = $ExternalPayrollCode and peci:Amount = $ExternalPayrollAmount])[last()]/peci:Start_Date = $BEGDA) and ((../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[@peci:isAdded = '1'][peci:Compensation_Plan = $ExternalPayrollCode and peci:Amount = $ExternalPayrollAmount])[last()]/peci:Number_of_Units)">
						<xsl:value-of
							select="(../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[@peci:isAdded = '1'][peci:Compensation_Plan = $ExternalPayrollCode  and peci:Amount = $ExternalPayrollAmount])[last()]/peci:Number_of_Units" />
					</xsl:when>
					<xsl:when
						test="((../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[@peci:isUpdated = '1'][peci:Compensation_Plan = $ExternalPayrollCode and peci:Amount = $ExternalPayrollAmount])[last()]/peci:Start_Date = $BEGDA) and ((../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[@peci:isUpdated = '1'][peci:Compensation_Plan = $ExternalPayrollCode and peci:Amount = $ExternalPayrollAmount])[last()]/peci:Number_of_Units)">
						<xsl:value-of
							select="(../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[@peci:isUpdated = '1'][peci:Compensation_Plan = $ExternalPayrollCode  and peci:Amount = $ExternalPayrollAmount])[last()]/peci:Number_of_Units" />
					</xsl:when>
					<xsl:when
						test="((../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[peci:Compensation_Plan = $ExternalPayrollCode and peci:Amount = $ExternalPayrollAmount/@peci:priorValue])[last()]/peci:Start_Date = $BEGDA) and ((../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[peci:Compensation_Plan = $ExternalPayrollCode and peci:Amount = $ExternalPayrollAmount/@peci:priorValue])[last()]/peci:Number_of_Units)">
						<xsl:value-of
							select="(../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[peci:Compensation_Plan = $ExternalPayrollCode  and peci:Amount = $ExternalPayrollAmount/@peci:priorValue])[last()]/peci:Number_of_Units" />
					</xsl:when>
					<xsl:otherwise />
				</xsl:choose>
			</ANZHL>
			<!-- ==== BLANK ==== -->
			<ZUORD xtt:fixedLength="19">
				<xsl:value-of select="''" />
			</ZUORD>
			<!-- ==== Match the correct instance of the allowance plan and take the 
				number of units ==== -->
			<ETEXT xtt:fixedLength="20">
				<xsl:choose>
					<xsl:when
						test="((../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[@peci:isAdded = '1'][peci:Compensation_Plan = $ExternalPayrollCode and peci:Amount = $ExternalPayrollAmount])[last()]/peci:Start_Date = $BEGDA) and ((../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[@peci:isAdded = '1'][peci:Compensation_Plan = $ExternalPayrollCode and peci:Amount = $ExternalPayrollAmount])[last()]/peci:Number_of_Units)">
						<xsl:value-of
							select="(../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[@peci:isAdded = '1'][peci:Compensation_Plan = $ExternalPayrollCode  and peci:Amount = $ExternalPayrollAmount])[last()]/peci:Number_of_Units" />
					</xsl:when>
					<xsl:when
						test="((../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[@peci:isUpdated = '1'][peci:Compensation_Plan = $ExternalPayrollCode and peci:Amount = $ExternalPayrollAmount])[last()]/peci:Start_Date = $BEGDA) and ((../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[@peci:isUpdated = '1'][peci:Compensation_Plan = $ExternalPayrollCode and peci:Amount = $ExternalPayrollAmount])[last()]/peci:Number_of_Units)">
						<xsl:value-of
							select="(../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[@peci:isUpdated = '1'][peci:Compensation_Plan = $ExternalPayrollCode  and peci:Amount = $ExternalPayrollAmount])[last()]/peci:Number_of_Units" />
					</xsl:when>
					<xsl:when
						test="((../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[peci:Compensation_Plan = $ExternalPayrollCode and peci:Amount = $ExternalPayrollAmount/@peci:priorValue])[last()]/peci:Start_Date = $BEGDA) and ((../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[peci:Compensation_Plan = $ExternalPayrollCode and peci:Amount = $ExternalPayrollAmount/@peci:priorValue])[last()]/peci:Number_of_Units)">
						<xsl:value-of
							select="(../../peci:Effective_Change/peci:Compensation_Plans/peci:Allowance_Plan[peci:Compensation_Plan = $ExternalPayrollCode  and peci:Amount = $ExternalPayrollAmount/@peci:priorValue])[last()]/peci:Number_of_Units" />
					</xsl:when>
					<xsl:otherwise />
				</xsl:choose>
			</ETEXT>
		</IT0014>
	</xsl:template>

	<!-- ==== INFOTYPE 0016 TEMPLATE ==== -->
	<xsl:template name="IT0016">
		<xsl:param name="Employee_ID" />
		<xsl:param name="ContractType" />
		<xsl:param name="ContractEndDate" />
		<xsl:param name="Effective_Moment" select="peci:Effective_Moment" />

		<IT0016 xtt:endTag="&#xd;&#xa;">
			<!-- ==== Workers Employee Id ==== -->
			<PERNR xtt:fixedLength="8">
				<xsl:value-of select="$Employee_ID" />
			</PERNR>
			<!-- ==== Hardcoded 0016 ==== -->
			<INFTY xtt:fixedLength="4">
				<xsl:value-of select="'0016'" />
			</INFTY>
			<!-- ==== BLANK ==== -->
			<BLANK xtt:fixedLength="4">
				<xsl:value-of select="''" />
			</BLANK>
			<!-- ==== Effective Moment ==== -->
			<BEGDA xtt:fixedLength="8" xtt:dateFormat="yyyyMMdd">
				<xsl:value-of select="xs:date(substring($Effective_Moment, 0, 11))" />
			</BEGDA>
			<!-- ==== Workers Contract Type ==== -->
			<CTTYP xtt:fixedLength="2">
				<xsl:value-of select="$ContractType" />
			</CTTYP>
			<!-- ==== Contract End Date ==== -->
			<CTEDT xtt:fixedLength="8" xtt:dateFormat="yyyyMMdd">
				<xsl:value-of
					select="
                        if ($ContractEndDate != '') then
                            xs:date(substring($ContractEndDate, 0, 11))
                        else
                            ''" />
			</CTEDT>
		</IT0016>
	</xsl:template>

	<!-- ==== INFOTYPE 0041 TEMPLATE ==== -->
	<xsl:template name="IT0041">
		<xsl:param name="Employee_ID" />
		<xsl:param name="HireDate" />
		<xsl:param name="SeniorityDate" />
		<xsl:param name="PayGroupAssignmentDate" />

		<IT0041 xtt:endTag="&#xd;&#xa;">
			<!-- ==== Workers Employee Id ==== -->
			<PERNR xtt:fixedLength="8">
				<xsl:value-of select="$Employee_ID" />
			</PERNR>
			<!-- ==== Hardcoded 0041 ==== -->
			<INFTY xtt:fixedLength="4">
				<xsl:value-of select="'0041'" />
			</INFTY>
			<!-- ==== BLANK ==== -->
			<BLANK xtt:fixedLength="4">
				<xsl:value-of select="''" />
			</BLANK>
			<!-- ==== Hardcoded 15 ==== -->
			<DAR01 xtt:fixedLength="2">
				<xsl:value-of select="'15'" />
			</DAR01>
			<!-- ==== Hire Date ==== -->
			<DAT01 xtt:fixedLength="8" xtt:dateFormat="yyyyMMdd">
				<xsl:value-of select="xs:date(substring($HireDate, 0, 11))" />
			</DAT01>
			<!-- ==== Hardcoded 5 ==== -->
			<DAR02 xtt:fixedLength="2">
				<xsl:value-of select="'05'" />
			</DAR02>
			<!-- ==== Seniority Date ==== -->
			<DAT02 xtt:fixedLength="8" xtt:dateFormat="yyyyMMdd">
				<xsl:value-of
					select="
                        if ($SeniorityDate != '') then
                            xs:date(substring($SeniorityDate, 0, 11))
                        else
                            ''" />
			</DAT02>
			<!-- ==== Hardcoded 95 ==== -->
			<DAR03 xtt:fixedLength="2">
				<xsl:value-of select="'95'" />
			</DAR03>
			<!-- ==== Pay Group Assignment Date ==== -->
			<DAT03 xtt:fixedLength="8" xtt:dateFormat="yyyyMMdd">
				<xsl:value-of
					select="
                        if ($PayGroupAssignmentDate != '') then
                            xs:date(substring($PayGroupAssignmentDate, 0, 11))
                        else
                            ''" />
			</DAT03>
		</IT0041>
	</xsl:template>

	<!-- ==== INFOTYPE 9010 TEMPLATE ==== -->
	<xsl:template name="IT9010">
		<xsl:param name="Employee_ID" />

		<IT9010 xtt:endTag="&#xd;&#xa;">
			<!-- ==== Workers Employee Id ==== -->
			<PERNR xtt:fixedLength="8">
				<xsl:value-of select="$Employee_ID" />
			</PERNR>
			<!-- ==== Hardcoded 9010 ==== -->
			<INFTY xtt:fixedLength="4">
				<xsl:value-of select="'9010'" />
			</INFTY>
			<!-- ==== BLANK ==== -->
			<BLANK xtt:fixedLength="4">
				<xsl:value-of select="''" />
			</BLANK>
			<!-- ==== If Leave End Date exists then Leave End Date ==== -->
			<!-- ==== Else Estimated Leave End Date ==== -->
			<ENDDA xtt:fixedLength="8" xtt:dateFormat="yyyyMMdd">
				<xsl:choose>
					<xsl:when test="peci:Leave_End_Date">
						<xsl:value-of select="xs:date(substring(peci:Leave_End_Date, 0, 11))" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of
							select="xs:date(substring(peci:Estimated_Leave_End_Date, 0, 11))" />
					</xsl:otherwise>
				</xsl:choose>
			</ENDDA>
			<!-- ==== Leave Start Date ==== -->
			<BEGDA xtt:fixedLength="8" xtt:dateFormat="yyyyMMdd">
				<xsl:value-of select="xs:date(substring(peci:Leave_Start_Date, 0, 11))" />
			</BEGDA>
			<!-- ==== Leave of Sbensce Type ==== -->
			<LGART xtt:fixedLength="4">
				<xsl:value-of select="peci:Leave_of_Absence_Type" />
			</LGART>
		</IT9010>
	</xsl:template>

	<!-- ==== INFOTYPE 2001 TEMPLATE ==== -->
	<xsl:template name="IT2001">
		<xsl:param name="Employee_ID" />
		<xsl:param name="Pay_Group" />

		<IT2001 xtt:endTag="&#xd;&#xa;">
			<!-- ==== Workers Employee Id ==== -->
			<PERNR xtt:fixedLength="8">
				<xsl:value-of select="$Employee_ID" />
			</PERNR>
			<!-- ==== Hardcoded 2001 ==== -->
			<INFTY xtt:fixedLength="4">
				<xsl:value-of select="'2001'" />
			</INFTY>
			<!-- ==== BLANK ==== -->
			<BLANK xtt:fixedLength="4">
				<xsl:value-of select="''" />
			</BLANK>
			<!-- ==== Effective Moment ==== -->
			<ENDDA xtt:fixedLength="8" xtt:dateFormat="yyyyMMdd">
				<xsl:value-of select="xs:date(substring(../peci:Effective_Moment, 0, 11))" />
			</ENDDA>
			<!-- ==== Effective Moment ==== -->
			<BEGDA xtt:fixedLength="8" xtt:dateFormat="yyyyMMdd">
				<xsl:value-of select="xs:date(substring(../peci:Effective_Moment, 0, 11))" />
			</BEGDA>
			<!-- ==== REMOVED - If Payroll Code is 402_404 and Job Category is Staff 
				then 404 ==== -->
			<!-- ==== REMOVED - If Payroll Code is 402_404 and Job Category is not 
				Staff then 402 ==== -->
			<!-- ==== REMOVED - If Payroll Code is 460_461 and Collective Agreement 
				is Staff or Operative then 461 ==== -->
			<!-- ==== REMOVED - If Payroll Code is 460_461 and Collective Agreement 
				is not Staff and not Operative then 460 ==== -->
			<!-- ==== LOGIC CHANGED - based on Pay group and NOT Job Category === -->
			<!-- ==== If pay group is F03 or F04 then 402 == -->
			<!-- ==== If pay group is F02, F17, F16, F30 then 404 == -->
			<LGART xtt:fixedLength="4">
				<xsl:choose>
					<xsl:when test="peci:External_Payroll_Code = '402_404'">
						<xsl:choose>
							<xsl:when test="$Pay_Group = ('F03','F04')">
								<xsl:value-of select="402" />
							</xsl:when>
							<xsl:when test="$Pay_Group = ('F02','F17','F16','F30')">
								<xsl:value-of select="404" />
							</xsl:when>
							<xsl:otherwise></xsl:otherwise>
						</xsl:choose>
						<!-- <xsl:choose> -->
						<!-- <xsl:when test="../peci:Position/peci:Job_Category = 'Staff'"> -->
						<!-- <xsl:value-of select="'404'"/> -->
						<!-- </xsl:when> -->
						<!-- <xsl:otherwise> -->
						<!-- <xsl:value-of select="'402'"/> -->
						<!-- </xsl:otherwise> -->
						<!-- </xsl:choose> -->
					</xsl:when>
					<xsl:when test="peci:External_Payroll_Code = '460_461'">
						<xsl:choose>
							<xsl:when
								test="contains(../peci:Additional_Information/ptdf:Collective_Agreement/ptdf:Collective_Agreement_ID, 'Staff') or contains(../peci:Additional_Information/ptdf:Collective_Agreement/ptdf:Collective_Agreement_ID, 'Operative')">
								<!-- == 20.09.2018 == -->
								<!-- == Temporary change to always send wage type 460 until other 
									fixes to Time off entries have been applied == -->
								<!-- == <xsl:value-of select="'461'"/> == -->
								<xsl:value-of select="'460'" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="'460'" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="peci:External_Payroll_Code" />
					</xsl:otherwise>
				</xsl:choose>

			</LGART>
			<!-- ==== Time Off Units ==== -->
			<UNIT xtt:fixedLength="14">
				<xsl:value-of select="peci:Time_Off_Entry/peci:Units" />
			</UNIT>
			<!-- ==== Effective Moment ==== -->
			<QYEAR xtt:fixedLength="4">
				<xsl:value-of select="substring(../peci:Effective_Moment, 0, 5)" />
			</QYEAR>
			<!-- ==== If Payroll Group is F03 or F04 then 2 ==== -->
			<!-- ==== If Payroll Group is F02, F17, F16 or F30 then 0 ==== -->
			<LOMAN_MAKSUMUOTO xtt:fixedLength="1">
				<xsl:choose>
					<xsl:when test="$Pay_Group = ('F03','F04')">
						<xsl:value-of select="2" />
					</xsl:when>
					<xsl:when test="$Pay_Group = ('F02','F17','F16','F30')">
						<xsl:value-of select="0" />
					</xsl:when>
					<xsl:otherwise></xsl:otherwise>
				</xsl:choose>
			</LOMAN_MAKSUMUOTO>
		</IT2001>
	</xsl:template>

	<!-- ==== INFOTYPE 0015 OTP TEMPLATE ==== -->
	<xsl:template name="IT0015">
		<xsl:param name="Employee_ID" />
		<xsl:param name="Effective_Date" />
		<xsl:param name="Amount" />

		<IT0015 xtt:endTag="&#xd;&#xa;">
			<!-- ==== Workers Employee Id ==== -->
			<PERNR xtt:fixedLength="8">
				<xsl:value-of select="$Employee_ID" />
			</PERNR>
			<!-- ==== Hardcoded 0015 ==== -->
			<INFTY xtt:fixedLength="4">
				<xsl:value-of select="'0015'" />
			</INFTY>
			<!-- ==== BLANK ==== -->
			<BLANK xtt:fixedLength="4">
				<xsl:value-of select="''" />
			</BLANK>
			<!-- ==== Effective Date ==== -->
			<BEGDA xtt:fixedLength="8" xtt:dateFormat="yyyyMMdd">
				<xsl:value-of select="$Effective_Date" />
			</BEGDA>
			<!-- ==== External Payroll Code, after IT0015_ and without letters ==== -->
			<LGART xtt:fixedLength="4">
				<xsl:value-of
					select="translate(substring-after(peci:External_Payroll_Code, 'IT0015_'), 'abcdefghijklmnopqrstuvqxyz', '')" />
			</LGART>
			<!-- ==== If parsed variable amount = zero then 0 ==== -->
			<!-- ==== Else Amount ==== -->
			<BETRG xtt:fixedLength="14">
				<xsl:choose>
					<xsl:when test="$Amount = 'zero'">
						<xsl:value-of select="'0'" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="peci:Amount" />
					</xsl:otherwise>
				</xsl:choose>

			</BETRG>
			<!-- ==== Worktag Code ==== -->
			<ZZCATS0006 xtt:fixedLength="5">
				<xsl:value-of select="peci:Worktag/peci:Worktag_Code" />
			</ZZCATS0006>
		</IT0015>
	</xsl:template>

	<xsl:variable name="TYELMap">
		<TYEL key="216_F04_2161120" value="110_15_00000005" />
		<TYEL key="216_F04_2161352" value="110_15_00000005" />
		<TYEL key="216_F04_2161353" value="110_15_00000005" />
		<TYEL key="216_F04_2161355" value="110_15_00000005" />
		<TYEL key="216_F04_2161356" value="110_15_00000005" />
		<TYEL key="216_F04_2161359" value="110_15_00000005" />
		<TYEL key="216_F04_2161371" value="110_15_00000005" />
		<TYEL key="216_F04_2161372" value="110_15_00000005" />
		<TYEL key="216_F04_2161373" value="110_15_00000005" />
		<TYEL key="216_F04_2161375" value="110_15_00000005" />
		<TYEL key="216_F04_2161407" value="110_15_00000005" />
		<TYEL key="216_F04_2161410" value="110_15_00000005" />
		<TYEL key="216_F04_2161411" value="110_15_00000005" />
		<TYEL key="216_F04_2161739" value="110_15_00000005" />
		<TYEL key="216_F04_2161740" value="110_15_00000005" />
		<TYEL key="216_F04_2161741" value="110_15_00000005" />
		<TYEL key="216_F04_2161750" value="110_15_00000005" />
		<TYEL key="216_F04_2161755" value="110_15_00000005" />
		<TYEL key="216_F16_2160215" value="131_15_00000005" />
		<TYEL key="216_F16_2161100" value="111_15_00000005" />
		<TYEL key="216_F16_2161102" value="111_15_00000005" />
		<TYEL key="216_F16_2161110" value="111_15_00000005" />
		<TYEL key="216_F16_2161119" value="111_15_00000005" />
		<TYEL key="216_F16_2161150" value="111_15_00000011" />
		<TYEL key="216_F16_2161152" value="111_15_00000005" />
		<TYEL key="216_F16_2161154" value="111_15_00000005" />
		<TYEL key="216_F16_2161155" value="111_15_00000005" />
		<TYEL key="216_F16_2161156" value="111_15_00000005" />
		<TYEL key="216_F16_2161157" value="111_15_00000005" />
		<TYEL key="216_F16_2161158" value="111_15_00000005" />
		<TYEL key="216_F16_2161159" value="111_15_00000005" />
		<TYEL key="216_F16_2161160" value="111_15_00000005" />
		<TYEL key="216_F16_2161162" value="111_15_00000005" />
		<TYEL key="216_F16_2161250" value="121_15_00000005" />
		<TYEL key="216_F16_2161253" value="121_15_00000005" />
		<TYEL key="216_F16_2161259" value="121_15_00000005" />
		<TYEL key="216_F16_2161262" value="121_15_00000005" />
		<TYEL key="216_F16_2161263" value="121_15_00000005" />
		<TYEL key="216_F16_2161264" value="121_15_00000005" />
		<TYEL key="216_F16_2161265" value="121_15_00000005" />
		<TYEL key="216_F16_2161269" value="121_15_00000005" />
		<TYEL key="216_F16_2161270" value="121_15_00000005" />
		<TYEL key="216_F16_2161271" value="121_15_00000005" />
		<TYEL key="216_F16_2161272" value="121_15_00000005" />
		<TYEL key="216_F16_2161273" value="121_15_00000005" />
		<TYEL key="216_F16_2161275" value="121_15_00000005" />
		<TYEL key="216_F16_2161276" value="121_15_00000005" />
		<TYEL key="216_F16_2161277" value="121_15_00000005" />
		<TYEL key="216_F16_2161279" value="121_15_00000005" />
		<TYEL key="216_F16_2161355" value="111_15_00000005" />
		<TYEL key="216_F16_2161360" value="111_15_00000005" />
		<TYEL key="216_F16_2161371" value="111_15_00000005" />
		<TYEL key="216_F16_2161373" value="111_15_00000005" />
		<TYEL key="216_F16_2161400" value="111_15_00000005" />
		<TYEL key="216_F16_2161407" value="111_15_00000005" />
		<TYEL key="216_F16_2161410" value="111_15_00000005" />
		<TYEL key="216_F16_2161731" value="111_15_00000005" />
		<TYEL key="216_F16_2161750" value="111_15_00000005" />
		<TYEL key="216_F16_2161755" value="111_15_00000005" />
		<TYEL key="216_F16_2161812" value="111_15_00000005" />
		<TYEL key="216_F16_2161818" value="111_15_00000005" />
		<TYEL key="216_F16_2161831" value="111_15_00000005" />
		<TYEL key="216_F16_2161832" value="111_15_00000005" />
		<TYEL key="216_F16_2161837" value="111_15_00000005" />
		<TYEL key="216_F16_2161861" value="111_15_00000005" />
		<TYEL key="216_F16_2161862" value="111_15_00000005" />
		<TYEL key="216_F16_2161877" value="111_15_00000005" />
		<TYEL key="216_F16_2161878" value="111_15_00000005" />
		<TYEL key="216_F16_2162106" value="161_15_00000005" />
		<TYEL key="216_F16_2162120" value="161_15_00000005" />
		<TYEL key="216_F16_2162121" value="161_15_00000005" />
		<TYEL key="216_F16_2162122" value="161_15_00000005" />
		<TYEL key="216_F16_2162123" value="161_15_00000011" />
		<TYEL key="216_F16_2162124" value="161_15_00000005" />
		<TYEL key="216_F16_2162125" value="161_15_00000005" />
		<TYEL key="216_F16_2162126" value="161_15_00000005" />
		<TYEL key="216_F16_2162127" value="161_15_00000005" />
		<TYEL key="216_F16_2162200" value="161_15_00000005" />
		<TYEL key="216_F16_2162201" value="161_15_00000005" />
		<TYEL key="216_F16_2162202" value="161_15_00000005" />
		<TYEL key="216_F16_2162205" value="161_15_00000005" />
		<TYEL key="216_F16_2162206" value="161_15_00000005" />
		<TYEL key="216_F16_2162207" value="161_15_00000005" />
		<TYEL key="216_F16_2162208" value="161_15_00000005" />
		<TYEL key="216_F16_2162209" value="161_15_00000005" />
		<TYEL key="216_F16_2162210" value="161_15_00000005" />
		<TYEL key="216_F16_2162211" value="161_15_00000005" />
		<TYEL key="216_F16_2162212" value="161_15_00000005" />
		<TYEL key="216_F16_2162214" value="161_15_00000005" />
		<TYEL key="216_F16_2162216" value="161_15_00000005" />
		<TYEL key="217_F03_2172920" value="300_15_00000012" />
		<TYEL key="217_F03_2172950" value="300_15_00000012" />
		<TYEL key="217_F03_2172960" value="300_15_00000012" />
		<TYEL key="217_F03_2172970" value="300_15_00000012" />
		<TYEL key="217_F03_2172980" value="300_15_00000014" />
		<TYEL key="217_F03_2172990" value="300_15_00000012" />
		<TYEL key="217_F03_2173070" value="300_15_00000012" />
		<TYEL key="217_F03_2173080" value="300_15_00000023" />
		<TYEL key="217_F03_2173090" value="300_15_00000012" />
		<TYEL key="217_F03_2173100" value="300_15_00000012" />
		<TYEL key="217_F03_2173110" value="190_15_00000005" />
		<TYEL key="217_F03_2173160" value="300_15_00000012" />
		<TYEL key="217_F03_2173190" value="300_15_00000012" />
		<TYEL key="217_F03_2173200" value="300_15_00000055" />
		<TYEL key="217_F03_2173300" value="300_15_00000012" />
		<TYEL key="217_F03_2173310" value="300_15_00000012" />
		<TYEL key="217_F03_2173320" value="300_15_00000012" />
		<TYEL key="217_F03_2173330" value="300_15_00000012" />
		<TYEL key="217_F03_2173340" value="300_15_00000012" />
		<TYEL key="217_F03_2173350" value="300_15_00000012" />
		<TYEL key="217_F03_2173360" value="300_15_00000012" />
		<TYEL key="217_F03_2173370" value="300_15_00000012" />
		<TYEL key="217_F03_2173380" value="300_15_00000005" />
		<TYEL key="217_F03_2173400" value="300_15_00000012" />
		<TYEL key="217_F03_2173410" value="300_15_00000012" />
		<TYEL key="217_F03_2173420" value="300_15_00000012" />
		<TYEL key="217_F03_2173430" value="300_15_00000012" />
		<TYEL key="217_F03_2173440" value="300_15_00000028" />
		<TYEL key="217_F03_2173450" value="300_15_00000012" />
		<TYEL key="217_F03_2173460" value="300_15_00000012" />
		<TYEL key="217_F03_2173470" value="300_15_00000012" />
		<TYEL key="217_F03_2173480" value="300_15_00000012" />
		<TYEL key="217_F03_2173490" value="300_15_00000012" />
		<TYEL key="217_F03_2173500" value="300_15_00000012" />
		<TYEL key="217_F03_2173510" value="300_15_00000020" />
		<TYEL key="217_F03_2173514" value="300_15_00000020" />
		<TYEL key="217_F03_2173520" value="300_15_00000021" />
		<TYEL key="217_F03_2173524" value="300_15_00000021" />
		<TYEL key="217_F03_2173530" value="300_15_00000017" />
		<TYEL key="217_F03_2173534" value="300_15_00000017" />
		<TYEL key="217_F03_2173540" value="300_15_00000018" />
		<TYEL key="217_F03_2173544" value="300_15_00000018" />
		<TYEL key="217_F03_2173550" value="300_15_00000016" />
		<TYEL key="217_F03_2173560" value="300_15_00000055" />
		<TYEL key="217_F03_2173570" value="300_15_00000055" />
		<TYEL key="217_F03_2173580" value="300_15_00000031" />
		<TYEL key="217_F03_2173610" value="300_15_00000019" />
		<TYEL key="217_F03_2173614" value="300_15_00000019" />
		<TYEL key="217_F03_2173620" value="300_15_00000015" />
		<TYEL key="217_F03_2173630" value="300_15_00000014" />
		<TYEL key="217_F03_2173640" value="300_15_00000019" />
		<TYEL key="217_F03_2173650" value="300_15_00000024" />
		<TYEL key="217_F03_2173660" value="300_15_00000023" />
		<TYEL key="217_F03_2173670" value="300_15_00000022" />
		<TYEL key="217_F03_2173680" value="300_15_00000031" />
		<TYEL key="217_F03_2173690" value="300_15_00000030" />
		<TYEL key="217_F03_2173710" value="300_15_00000040" />
		<TYEL key="217_F03_2173714" value="300_15_00000028" />
		<TYEL key="217_F03_2173720" value="300_15_00000028" />
		<TYEL key="217_F03_2173730" value="300_15_00000026" />
		<TYEL key="217_F03_2173734" value="300_15_00000027" />
		<TYEL key="217_F03_2173740" value="300_15_00000055" />
		<TYEL key="217_F03_2173750" value="300_15_00000032" />
		<TYEL key="217_F03_2173760" value="300_15_00000019" />
		<TYEL key="217_F03_2173770" value="300_15_00000019" />
		<TYEL key="217_F03_2173790" value="300_15_00000012" />
		<TYEL key="217_F03_2173810" value="300_15_00000032" />
		<TYEL key="217_F03_2173814" value="300_15_00000032" />
		<TYEL key="217_F03_2173820" value="300_15_00000022" />
		<TYEL key="217_F03_2173824" value="300_15_00000022" />
		<TYEL key="217_F03_2173830" value="300_15_00000032" />
		<TYEL key="217_F03_2173840" value="300_15_00000046" />
		<TYEL key="217_F03_2173850" value="300_15_00000041" />
		<TYEL key="217_F03_2173860" value="300_15_00000035" />
		<TYEL key="217_F03_2173864" value="300_15_00000035" />
		<TYEL key="217_F03_2173870" value="300_15_00000025" />
		<TYEL key="217_F03_2173880" value="300_15_00000015" />
		<TYEL key="217_F03_2173890" value="300_15_00000020" />
		<TYEL key="217_F03_2173910" value="300_15_00000055" />
		<TYEL key="217_F03_2173915" value="300_15_00000012" />
		<TYEL key="217_F03_2173920" value="300_15_00000012" />
		<TYEL key="217_F03_2173930" value="300_15_00000018" />
		<TYEL key="217_F03_2173940" value="300_15_00000055" />
		<TYEL key="217_F03_2173950" value="300_15_00000014" />
		<TYEL key="217_F03_2173960" value="300_15_00000012" />
		<TYEL key="217_F03_2173970" value="300_15_00000012" />
		<TYEL key="217_F03_2173980" value="300_15_00000035" />
		<TYEL key="217_F03_2173990" value="300_15_00000055" />
		<TYEL key="217_F17_2171013" value="401_15_00000011" />
		<TYEL key="217_F17_2171019" value="401_15_00000011" />
		<TYEL key="217_F17_2172940" value="301_15_00000018" />
		<TYEL key="217_F17_2172950" value="301_15_00000012" />
		<TYEL key="217_F17_2173010" value="301_15_00000012" />
		<TYEL key="217_F17_2173020" value="301_15_00000012" />
		<TYEL key="217_F17_2173040" value="301_15_00000012" />
		<TYEL key="217_F17_2173050" value="301_15_00000012" />
		<TYEL key="217_F17_2173060" value="301_15_00000012" />
		<TYEL key="217_F17_2173130" value="301_15_00000012" />
		<TYEL key="217_F17_2173150" value="301_15_00000012" />
		<TYEL key="217_F17_2173170" value="301_15_00000014" />
		<TYEL key="217_F17_2173200" value="301_15_00000055" />
		<TYEL key="217_F17_2173210" value="301_15_00000019" />
		<TYEL key="217_F17_2173220" value="301_15_00000012" />
		<TYEL key="217_F17_2173240" value="301_15_00000012" />
		<TYEL key="217_F17_2173250" value="301_15_00000012" />
		<TYEL key="217_F17_2173260" value="301_15_00000012" />
		<TYEL key="217_F17_2173270" value="301_15_00000012" />
		<TYEL key="217_F17_2173280" value="301_15_00000012" />
		<TYEL key="217_F17_2173390" value="301_15_00000012" />
		<TYEL key="217_F17_2173500" value="301_15_00000012" />
		<TYEL key="217_F17_2173590" value="301_15_00000040" />
		<TYEL key="217_F17_2173600" value="301_15_00000032" />
		<TYEL key="217_F17_2173700" value="301_15_00000012" />
		<TYEL key="217_F17_2173780" value="301_15_00000012" />
		<TYEL key="217_F17_2173800" value="301_15_00000018" />
		<TYEL key="217_F17_2173804" value="301_15_00000032" />
		<TYEL key="217_F17_2173900" value="301_15_00000012" />
		<TYEL key="217_F17_2173910" value="301_15_00000055" />
		<TYEL key="217_F17_2173915" value="301_15_00000012" />
		<TYEL key="217_F17_2173960" value="301_15_00000012" />
		<TYEL key="217_F17_2175001" value="401_15_00000005" />
		<TYEL key="217_F17_2175010" value="401_15_00000005" />
		<TYEL key="217_F17_2175012" value="401_15_00000005" />
		<TYEL key="217_F17_2175030" value="401_15_00000005" />
		<TYEL key="217_F17_2176004" value="401_15_00000011" />
		<TYEL key="217_F30_2171019" value="999_15_00000099" />
		<TYEL key="217_F30_2174010" value="999_15_00000099" />
		<TYEL key="271_F09_2712000" value="000_15_00000012" />
		<TYEL key="271_F27_2712000" value="000_15_00000012" />
		<TYEL key="KNE_F02_KNE0002" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0020" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0051" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0052" value="001_15_00000005" />
		<TYEL key="KNE_F02_KNE0054" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0056" value="001_15_00000005" />
		<TYEL key="KNE_F02_KNE0057" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0058" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0110" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0114" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0115" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0117" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0120" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0139" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0141" value="001_15_00000005" />
		<TYEL key="KNE_F02_KNE0142" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0143" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0144" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0145" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0148" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0149" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0170" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0171" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0180" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0181" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0182" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0183" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0190" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0193" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0194" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0240" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0311" value="001_15_00000005" />
		<TYEL key="KNE_F02_KNE0312" value="001_15_00000005" />
		<TYEL key="KNE_F02_KNE0313" value="001_15_00000005" />
		<TYEL key="KNE_F02_KNE0400" value="001_15_00000005" />
		<TYEL key="KNE_F02_KNE0410" value="001_15_00000005" />
		<TYEL key="KNE_F02_KNE0420" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0430" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0500" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0640" value="001_15_00000005" />
		<TYEL key="KNE_F02_KNE0642" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0650" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0652" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0655" value="001_15_00000005" />
		<TYEL key="KNE_F02_KNE0656" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0657" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0658" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0659" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0700" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0800" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0900" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0910" value="001_15_00000005" />
		<TYEL key="KNE_F02_KNE1037" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1039" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1041" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1047" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1048" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1049" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1052" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1053" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1054" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1056" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1057" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1058" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1059" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1060" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1061" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1062" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1063" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1064" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1065" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1066" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1067" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1068" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1069" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1070" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1071" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1072" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1073" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1074" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1085" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1086" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1090" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1093" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE1094" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNEG300" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNEG301" value="001_15_00000005" />
		<TYEL key="KNE_F02_KNEG302" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNEG306" value="001_15_00000005" />
		<TYEL key="KNE_F02_KNEG307" value="001_15_00000005" />
		<TYEL key="KNE_F02_KNEG308" value="001_15_00000005" />
		<TYEL key="KNE_F02_KNEG310" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNEG320" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNEG330" value="001_15_00000005" />
		<TYEL key="KNE_F02_KNEG331" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNEG340" value="001_15_00000005" />
		<TYEL key="KNE_F02_KNEG350" value="001_15_00000005" />
		<TYEL key="KNE_F02_KNEG361" value="001_15_00000005" />
		<TYEL key="KNE_F02_KNEG364" value="001_15_00000005" />
		<TYEL key="KNE_F02_KNEG370" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNEG371" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNEG372" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNEG381" value="001_15_00000005" />
		<TYEL key="KNE_F02_KNEG390" value="001_15_00000011" />
		<TYEL key="KNE_F30_KNE0058" value="001_15_00000011" />
		<TYEL key="KNE_F30_KNE0114" value="999_15_00000099" />
		<TYEL key="KNE_F30_KNE0115" value="999_15_00000099" />
		<TYEL key="KNE_F30_KNE0182" value="999_15_00000099" />
		<TYEL key="KNE_F30_KNE0183" value="001_15_00000011" />
		<TYEL key="KNE_F30_KNE0400" value="999_15_00000011" />
		<TYEL key="KNE_F30_KNE0410" value="999_15_00000099" />
		<TYEL key="KNE_F30_KNE0508" value="999_15_00000099" />
		<TYEL key="KNE_F30_KNE0512" value="999_15_00000099" />
		<TYEL key="KNE_F30_KNE0513" value="999_15_00000099" />
		<TYEL key="KNE_F30_KNE0516" value="999_15_00000099" />
		<TYEL key="KNE_F30_KNE0519" value="999_15_00000099" />
		<TYEL key="KNE_F30_KNE0526" value="999_15_00000099" />
		<TYEL key="KNE_F30_KNE0529" value="999_15_00000099" />
		<TYEL key="KNE_F30_KNE0540" value="999_15_00000099" />
		<TYEL key="KNE_F30_KNE0545" value="999_15_00000099" />
		<TYEL key="KNE_F30_KNE0592" value="999_15_00000099" />
		<TYEL key="KNE_F30_KNE0640" value="001_15_00000011" />
		<TYEL key="KNE_F30_KNE0800" value="999_15_00000099" />
		<TYEL key="KNE_F30_KNE0801" value="999_15_00000099" />
		<TYEL key="KNE_F30_KNEG301" value="999_15_00000099" />
		<TYEL key="KNE_F30_KNEG370" value="001_15_00000011" />
		<!-- Updates to mappings 08.10.2018 -->
		<TYEL key="217_F03_2173664" value="300_15_00000023" />
		<TYEL key="217_F03_2173674" value="300_15_00000031" />
		<TYEL key="KNE_F02_KNE0146" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0147" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0150" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0154" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0184" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE0440" value="001_15_00000005" />
		<TYEL key="KNE_F02_KNE0904" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE1078" value="091_15_00000005" />
		<TYEL key="KNE_F02_KNE2000" value="001_15_00000005" />
		<TYEL key="KNE_F02_KNE2100" value="001_15_00000005" />
		<TYEL key="KNE_F02_KNE2150" value="001_15_00000005" />
		<TYEL key="KNE_F02_KNE2200" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNE2300" value="001_15_00000012" />
		<TYEL key="KNE_F02_KNEG312" value="001_15_00000011" />
		<TYEL key="KNE_F02_KNEG341" value="001_15_00000005" />
		<TYEL key="216_F16_2161274" value="121_15_00000005" />
		<TYEL key="216_F04_2161406" value="110_15_00000005" />
		<TYEL key="216_F04_2161756" value="110_15_00000005" />
		<TYEL key="217_F17_2173592" value="301_15_00000019" />
		<TYEL key="217_F17_2179000" value="301_15_00000012" />
	</xsl:variable>

	<!-- Function peci:elementChanged() purpose is to determine if specific 
		element within the processed "peci:Effective_Change" node has changed -->
	<!-- Applicable only for single instance elements -->
	<!-- Output codes: -->
	<!-- CH1, CHP, CHA - change indicators -->
	<!-- CH1 = there's just one field within Effective Change -->
	<!-- CHA - there are two fields and we need to look for the new value within 
		an ancestor with appropriate change indicator -->
	<!-- CHP - there are two fields and we need to look for the new value within 
		a parent with a proper change indicator -->
	<!-- N - no change -->
	<!-- D - value deleted -->
	<!-- The output code can be then used as an input to function peci:setNewPath 
		that returns a new value if there was a change -->
	<xsl:function name="peci:elementChanged">
		<xsl:param name="element" />
		<xsl:choose>
			<xsl:when
				test="count($element/ancestor::peci:Effective_Change//$element) = 1">
				<xsl:choose>
					<xsl:when
						test="$element/../@peci:isAdded or $element/@peci:isAdded or exists($element/ancestor::*[@peci:isAdded and name(..) = 'peci:Effective_Change'])">
						<xsl:value-of select="'CH1'" />
					</xsl:when>
					<xsl:when
						test="$element/../@peci:isUpdated or $element/@peci:isUpdated or exists($element/ancestor::*[@peci:isUpdated and name(..) = 'peci:Effective_Change'])">
						<xsl:value-of select="'CH1'" />
					</xsl:when>
					<xsl:when
						test="$element/../@peci:isDeleted or $element/@peci:isDeleted or exists($element/ancestor::*[@peci:isDeleted and name(..) = 'peci:Effective_Change'])">
						<xsl:value-of select="'D'" />
					</xsl:when>
					<xsl:when test="$element/@peci:priorValue">
						<xsl:choose>
							<xsl:when test="$element = ''">
								<xsl:value-of select="'D'" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="'CH1'" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="'N'" />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when
				test="count($element/ancestor::peci:Effective_Change//$element) = 2">
				<xsl:choose>
					<xsl:when
						test="$element[../@peci:isAdded] != $element[../not(exists(@peci:isAdded))]">
						<xsl:value-of select="'CHP'" />
					</xsl:when>
					<xsl:when
						test="exists($element/ancestor::*[name(..) = 'peci:Effective_Change'])">
						<xsl:choose>
							<xsl:when
								test="$element[ancestor::*[@peci:isAdded and name(..) = 'peci:Effective_Change']] != $element[ancestor::*[not(@peci:isAdded) and name(..) = 'peci:Effective_Change']]">
								<xsl:value-of select="'CHA'" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="'N'" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="'N'" />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="'N'" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<xsl:function name="peci:setNewPath">
		<xsl:param name="path" />
		<xsl:param name="elementChangedFlag" />

		<xsl:choose>
			<xsl:when test="$elementChangedFlag = 'CHP'">
				<xsl:value-of select="$path[../@peci:isAdded]" />
			</xsl:when>
			<xsl:when test="$elementChangedFlag = 'CHA'">
				<xsl:value-of
					select="$path[ancestor::*[name(..) = 'peci:Effective_Change' and @peci:isAdded]]" />
			</xsl:when>
			<xsl:when test="$elementChangedFlag = 'CH1'">
				<xsl:value-of select="$path" />
			</xsl:when>
		</xsl:choose>
	</xsl:function>

</xsl:stylesheet>