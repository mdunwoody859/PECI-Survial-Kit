<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:peci="urn:com.workday/peci" xmlns:wd="urn:com.workday/bsvc" xmlns:etv="urn:com.workday/etv" xmlns:ptdf="urn:com.workday/peci/tdf" xmlns:func="http://func.com" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="xs" version="2.0">

	<!-- TOP OF STACK PECI -->

	<xsl:template match="peci:Workers_Effective_Stack">
		<ePayfact_GIF_XML>
			<ePayfactHeader/>
			<Data>
				<Payroll>
					<etv:class etv:name="notReqWithWarn" etv:required="false" etv:severity="warning" etv:omit="true" etv:truncate="true"/>
					<etv:class etv:name="reqWithErr" etv:required="true" etv:severity="error" etv:omit="true" etv:truncate="false"/>
					<xsl:apply-templates select="peci:Worker"/>
				</Payroll>
			</Data>
		</ePayfact_GIF_XML>
	</xsl:template>

	<xsl:template match="peci:Worker">

		<xsl:variable name="WorkerWID">
			<xsl:value-of select="peci:Effective_Change[exists(peci:Additional_Information/peci:WorkerID)][1]/peci:Additional_Information[exists(peci:WorkerID)][1]/peci:WorkerID"/>
		</xsl:variable>
		<xsl:variable name="EmployeeNo">
			<xsl:value-of select="peci:Worker_Summary/peci:Employee_ID"/>
		</xsl:variable>
		<xsl:variable name="EffectiveDate">
			<xsl:value-of select="format-date(xs:date(substring(xs:string(xs:date(current-date())), 0, 11)), '[D01]/[M01]/[Y0001]')"/>
		</xsl:variable>
		<xsl:variable name="NINumber">
			<xsl:if test="peci:Effective_Change/peci:Person_Identification/peci:National_Identifier/peci:National_ID">
				<xsl:for-each select="peci:Effective_Change[peci:Person_Identification/peci:National_Identifier/peci:National_ID]">
					<xsl:sort select="peci:Effective_Moment" order="descending"/>
					<xsl:if test="position() = 1">
						<xsl:choose>
							<xsl:when test="
									((peci:Person_Identification/@peci:isDeleted and not(peci:Person_Identification/@peci:isAdded) and not(peci:Person_Identification/@peci:isUpdated))
									or (peci:Person_Identification/peci:National_Identifier/@peci:isDeleted and not(peci:Person_Identification/peci:National_Identifier/@peci:isAdded) and not(peci:Person_Identification/peci:National_Identifier/@peci:isUpdated))
									or (peci:Person_Identification/peci:National_Identifier/peci:National_ID/@peci:isDeleted and not(peci:Person_Identification/peci:National_Identifier/peci:National_ID/@peci:isAdded) and not(peci:Person_Identification/peci:National_Identifier/peci:National_ID/@peci:isUpdated)))
									or (count(peci:Person_Identification/peci:National_Identifier/peci:National_ID) = 1
									and peci:Person_Identification/peci:National_Identifier/peci:National_ID/@peci:priorValue != ''
									and peci:Person_Identification/peci:National_Identifier/peci:National_ID = '')">
								<xsl:value-of select="'NULL'"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="translate(peci:Person_Identification[not(@peci:isDeleted)]/peci:National_Identifier[not(@peci:isDeleted)]/peci:National_ID[not(@peci:isDeleted)], '- ', '')"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:if>
				</xsl:for-each>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="NewStarter">
			<xsl:choose>
				<xsl:when test="peci:Effective_Change/peci:Derived_Event_Code = 'HIR'">
					<xsl:value-of select="'Y'"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="'N'"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="PayGroup">
			<xsl:if test="peci:Effective_Change/peci:Personal/peci:Legal_Name/peci:Last_Name">
				<xsl:for-each select="peci:Effective_Change[peci:Personal/peci:Legal_Name/peci:Last_Name]">
					<xsl:sort select="peci:Effective_Moment" order="descending"/>
					<xsl:if test="position() = 1">
						<xsl:choose>
							<xsl:when test="
									((peci:Personal/@peci:isDeleted and not(peci:Personal/@peci:isAdded) and not(peci:Personal/@peci:isUpdated))
									or (peci:Personal/peci:Legal_Name/@peci:isDeleted and not(peci:Personal/peci:Legal_Name/@peci:isAdded) and not(peci:Personal/peci:Legal_Name/@peci:isUpdated))
									or (peci:Personal/peci:Legal_Name/peci:Last_Name/@peci:isDeleted and not(peci:Personal/peci:Legal_Name/peci:Last_Name/@peci:isAdded) and not(peci:Personal/peci:Legal_Name/peci:Last_Name/@peci:isUpdated)))
									or (count(peci:Personal/peci:Legal_Name/peci:Last_Name) = 1
									and peci:Personal/peci:Legal_Name/peci:Last_Name/@peci:priorValue != ''
									and peci:Personal/peci:Legal_Name/peci:Last_Name = '')">
								<xsl:value-of select="'NULL'"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="peci:Personal[not(@peci:isDeleted)]/peci:Legal_Name[not(@peci:isDeleted)]/peci:Last_Name[not(@peci:isDeleted)]"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:if>
				</xsl:for-each>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="Surname">
			<xsl:if test="peci:Effective_Change/peci:Personal/peci:Legal_Name/peci:Last_Name">
				<xsl:for-each select="peci:Effective_Change[peci:Personal/peci:Legal_Name/peci:Last_Name]">
					<xsl:sort select="peci:Effective_Moment" order="descending"/>
					<xsl:if test="position() = 1">
						<xsl:choose>
							<xsl:when test="
									((peci:Personal/@peci:isDeleted and not(peci:Personal/@peci:isAdded) and not(peci:Personal/@peci:isUpdated))
									or (peci:Personal/peci:Legal_Name/@peci:isDeleted and not(peci:Personal/peci:Legal_Name/@peci:isAdded) and not(peci:Personal/peci:Legal_Name/@peci:isUpdated))
									or (peci:Personal/peci:Legal_Name/peci:Last_Name/@peci:isDeleted and not(peci:Personal/peci:Legal_Name/peci:Last_Name/@peci:isAdded) and not(peci:Personal/peci:Legal_Name/peci:Last_Name/@peci:isUpdated)))
									or (count(peci:Personal/peci:Legal_Name/peci:Last_Name) = 1
									and peci:Personal/peci:Legal_Name/peci:Last_Name/@peci:priorValue != ''
									and peci:Personal/peci:Legal_Name/peci:Last_Name = '')">
								<xsl:value-of select="'NULL'"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="peci:Personal[not(@peci:isDeleted)]/peci:Legal_Name[not(@peci:isDeleted)]/peci:Last_Name[not(@peci:isDeleted)]"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:if>
				</xsl:for-each>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="Forename1">
			<xsl:if test="peci:Effective_Change/peci:Personal/peci:Legal_Name/peci:First_Name">
				<xsl:for-each select="peci:Effective_Change[peci:Personal/peci:Legal_Name/peci:First_Name]">
					<xsl:sort select="peci:Effective_Moment" order="descending"/>
					<xsl:if test="position() = 1">
						<xsl:choose>
							<xsl:when test="
									((peci:Personal/@peci:isDeleted and not(peci:Personal/@peci:isAdded) and not(peci:Personal/@peci:isUpdated))
									or (peci:Personal/peci:Legal_Name/@peci:isDeleted and not(peci:Personal/peci:Legal_Name/@peci:isAdded) and not(peci:Personal/peci:Legal_Name/@peci:isUpdated))
									or (peci:Personal/peci:Legal_Name/peci:First_Name/@peci:isDeleted and not(peci:Personal/peci:Legal_Name/peci:First_Name/@peci:isAdded) and not(peci:Personal/peci:Legal_Name/peci:First_Name/@peci:isUpdated)))
									or (count(peci:Personal/peci:Legal_Name/peci:First_Name) = 1
									and peci:Personal/peci:Legal_Name/peci:First_Name/@peci:priorValue != ''
									and peci:Personal/peci:Legal_Name/peci:First_Name = '')">
								<xsl:value-of select="'NULL'"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="peci:Personal[not(@peci:isDeleted)]/peci:Legal_Name[not(@peci:isDeleted)]/peci:First_Name[not(@peci:isDeleted)]"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:if>
				</xsl:for-each>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="Forename2">
			<xsl:if test="peci:Effective_Change/peci:Personal/peci:Legal_Name/peci:Middle_Name">
				<xsl:for-each select="peci:Effective_Change[peci:Personal/peci:Legal_Name/peci:Middle_Name]">
					<xsl:sort select="peci:Effective_Moment" order="descending"/>
					<xsl:if test="position() = 1">
						<xsl:choose>
							<xsl:when test="
									((peci:Personal/@peci:isDeleted and not(peci:Personal/@peci:isAdded) and not(peci:Personal/@peci:isUpdated))
									or (peci:Personal/peci:Legal_Name/@peci:isDeleted and not(peci:Personal/peci:Legal_Name/@peci:isAdded) and not(peci:Personal/peci:Legal_Name/@peci:isUpdated))
									or (peci:Personal/peci:Legal_Name/peci:Middle_Name/@peci:isDeleted and not(peci:Personal/peci:Legal_Name/peci:Middle_Name/@peci:isAdded) and not(peci:Personal/peci:Legal_Name/peci:Middle_Name/@peci:isUpdated)))
									or (count(peci:Personal/peci:Legal_Name/peci:Middle_Name) = 1
									and peci:Personal/peci:Legal_Name/peci:Middle_Name/@peci:priorValue != ''
									and peci:Personal/peci:Legal_Name/peci:Middle_Name = '')">
								<xsl:value-of select="'NULL'"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="peci:Personal[not(@peci:isDeleted)]/peci:Legal_Name[not(@peci:isDeleted)]/peci:Middle_Name[not(@peci:isDeleted)]"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:if>
				</xsl:for-each>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="MaritalStatus">
			<xsl:if test="peci:Effective_Change/peci:Personal/peci:Marital_Status">
				<xsl:for-each select="peci:Effective_Change[peci:Personal/peci:Marital_Status]">
					<xsl:sort select="peci:Effective_Moment" order="descending"/>
					<xsl:if test="position() = 1">
						<xsl:choose>
							<xsl:when test="
									((peci:Personal/@peci:isDeleted and not(peci:Personal/@peci:isAdded) and not(peci:Personal/@peci:isUpdated))
									or (peci:Personal/peci:Marital_Status/@peci:isDeleted and not(peci:Personal/peci:Marital_Status/@peci:isAdded) and not(peci:Personal/peci:Marital_Status/@peci:isUpdated)))
									or (count(peci:Personal/peci:Marital_Status) = 1
									and peci:Personal/peci:Marital_Status/@peci:priorValue != ''
									and peci:Personal/peci:Marital_Status = '')">
								<xsl:value-of select="'NULL'"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:choose>
									<xsl:when test="not(peci:Personal[not(@peci:isDeleted)]/peci:Marital_Status[not(@peci:isDeleted)] = 'BLANK')">
										<xsl:value-of select="peci:Personal[not(@peci:isDeleted)]/peci:Marital_Status[not(@peci:isDeleted)]"/>
									</xsl:when>
									<xsl:otherwise/>
								</xsl:choose>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:if>
				</xsl:for-each>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="KnownAs">
			<xsl:if test="peci:Effective_Change/peci:Personal/peci:Preferred_Name/peci:First_Name">
				<xsl:for-each select="peci:Effective_Change[peci:Personal/peci:Preferred_Name/peci:First_Name]">
					<xsl:sort select="peci:Effective_Moment" order="descending"/>
					<xsl:if test="position() = 1">
						<xsl:choose>
							<xsl:when test="
									((peci:Personal/@peci:isDeleted and not(peci:Personal/@peci:isAdded) and not(peci:Personal/@peci:isUpdated))
									or (peci:Personal/peci:Preferred_Name/@peci:isDeleted and not(peci:Personal/peci:Preferred_Name/@peci:isAdded) and not(peci:Personal/peci:Preferred_Name/@peci:isUpdated))
									or (peci:Personal/peci:Preferred_Name/peci:First_Name/@peci:isDeleted and not(peci:Personal/peci:Preferred_Name/peci:First_Name/@peci:isAdded) and not(peci:Personal/peci:Preferred_Name/peci:First_Name/@peci:isUpdated)))
									or (count(peci:Personal/peci:Preferred_Name/peci:First_Name) = 1
									and peci:Personal/peci:Preferred_Name/peci:First_Name/@peci:priorValue != ''
									and peci:Personal/peci:Preferred_Name/peci:First_Name = '')">
								<xsl:value-of select="'NULL'"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="peci:Personal[not(@peci:isDeleted)]/peci:Preferred_Name[not(@peci:isDeleted)]/peci:First_Name[not(@peci:isDeleted)]"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:if>
				</xsl:for-each>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="Title">
			<xsl:if test="peci:Effective_Change/peci:Personal/peci:Legal_Name/peci:Title">
				<xsl:for-each select="peci:Effective_Change[peci:Personal/peci:Legal_Name/peci:Title]">
					<xsl:sort select="peci:Effective_Moment" order="descending"/>
					<xsl:if test="position() = 1">
						<xsl:choose>
							<xsl:when test="
									((peci:Personal/@peci:isDeleted and not(peci:Personal/@peci:isAdded) and not(peci:Personal/@peci:isUpdated))
									or (peci:Personal/peci:Legal_Name/@peci:isDeleted and not(peci:Personal/peci:Legal_Name/@peci:isAdded) and not(peci:Personal/peci:Legal_Name/@peci:isUpdated))
									or (peci:Personal/peci:Legal_Name/peci:Title/@peci:isDeleted and not(peci:Personal/peci:Legal_Name/peci:Title/@peci:isAdded) and not(peci:Personal/peci:Legal_Name/peci:Title/@peci:isUpdated)))
									or (count(peci:Personal/peci:Legal_Name/peci:Title) = 1
									and peci:Personal/peci:Legal_Name/peci:Title/@peci:priorValue != ''
									and peci:Personal/peci:Legal_Name/peci:Title = '')">
								<xsl:value-of select="'NULL'"/>
							</xsl:when>
							<xsl:otherwise>
						
							</xsl:otherwise>
						</xsl:choose>
					</xsl:if>
				</xsl:for-each>
			</xsl:if>
		</xsl:variable>
		<!-- Address -->
		<xsl:variable name="Address1_temp">
			<xsl:for-each select="peci:Effective_Change[peci:Person_Communication/peci:Address]">
				<xsl:sort select="peci:Effective_Moment" order="descending"/>
				<xsl:if test="position() = 1">

					<xsl:choose>
						<xsl:when test="
								((peci:Person_Communication/@peci:isDeleted and not(peci:Person_Communication/@peci:isAdded) and not(peci:Person_Communication/@peci:isUpdated))
								or (peci:Person_Communication/peci:Address/@peci:isDeleted and not(peci:Person_Communication/peci:Address/@peci:isAdded) and not(peci:Person_Communication/peci:Address/@peci:isUpdated))
								or (peci:Person_Communication/peci:Address/peci:Address_Line_1/@peci:isDeleted and not(peci:Person_Communication/peci:Address/peci:Address_Line_1/@peci:isAdded) and not(peci:Person_Communication/peci:Address/peci:Address_Line_1/@peci:isUpdated)))
								or (count(peci:Person_Communication/peci:Address/peci:Address_Line_1) = 1
								and peci:Person_Communication/peci:Address/peci:Address_Line_1/@peci:priorValue != ''
								and peci:Person_Communication/peci:Address/peci:Address_Line_1 = '')">
							<xsl:value-of select="'NULL'"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:choose>
								<xsl:when test="peci:Person_Communication[not(@peci:isDeleted)]/peci:Address[not(@peci:isDeleted)]/peci:Address_Line_1[not(@peci:isDeleted)] != ''">
									<xsl:value-of select="peci:Person_Communication[not(@peci:isDeleted)]/peci:Address[not(@peci:isDeleted)]/peci:Address_Line_1[not(@peci:isDeleted)]"/>
								</xsl:when>
								<xsl:otherwise> </xsl:otherwise>
							</xsl:choose>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="Address2_temp">
			<xsl:for-each select="peci:Effective_Change[peci:Person_Communication/peci:Address]">
				<xsl:sort select="peci:Effective_Moment" order="descending"/>
				<xsl:if test="position() = 1">
					<xsl:choose>
						<xsl:when test="
								((peci:Person_Communication/@peci:isDeleted and not(peci:Person_Communication/@peci:isAdded) and not(peci:Person_Communication/@peci:isUpdated))
								or (peci:Person_Communication/peci:Address/@peci:isDeleted and not(peci:Person_Communication/peci:Address/@peci:isAdded) and not(peci:Person_Communication/peci:Address/@peci:isUpdated))
								or (peci:Person_Communication/peci:Address/peci:Address_Line_2/@peci:isDeleted and not(peci:Person_Communication/peci:Address/peci:Address_Line_2/@peci:isAdded) and not(peci:Person_Communication/peci:Address/peci:Address_Line_2/@peci:isUpdated)))
								or (count(peci:Person_Communication/peci:Address/peci:Address_Line_2) = 1
								and peci:Person_Communication/peci:Address/peci:Address_Line_2/@peci:priorValue != ''
								and peci:Person_Communication/peci:Address/peci:Address_Line_2 = '')">
							<xsl:value-of select="'NULL'"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:choose>
								<xsl:when test="peci:Person_Communication[not(@peci:isDeleted)]/peci:Address[not(@peci:isDeleted)]/peci:Address_Line_2[not(@peci:isDeleted)] != ''">
									<xsl:value-of select="peci:Person_Communication[not(@peci:isDeleted)]/peci:Address[not(@peci:isDeleted)]/peci:Address_Line_2[not(@peci:isDeleted)]"/>
								</xsl:when>
								<xsl:otherwise/>
							</xsl:choose>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="Address3_temp">
			<xsl:for-each select="peci:Effective_Change[peci:Person_Communication/peci:Address]">
				<xsl:sort select="peci:Effective_Moment" order="descending"/>
				<xsl:if test="position() = 1">
					<xsl:choose>
						<xsl:when test="
								((peci:Person_Communication/@peci:isDeleted and not(peci:Person_Communication/@peci:isAdded) and not(peci:Person_Communication/@peci:isUpdated))
								or (peci:Person_Communication/peci:Address/@peci:isDeleted and not(peci:Person_Communication/peci:Address/@peci:isAdded) and not(peci:Person_Communication/peci:Address/@peci:isUpdated))
								or (peci:Person_Communication/peci:Address/peci:Address_Line_3/@peci:isDeleted and not(peci:Person_Communication/peci:Address/peci:Address_Line_3/@peci:isAdded) and not(peci:Person_Communication/peci:Address/peci:Address_Line_3/@peci:isUpdated)))
								or (count(peci:Person_Communication/peci:Address/peci:Address_Line_3) = 1
								and peci:Person_Communication/peci:Address/peci:Address_Line_3/@peci:priorValue != ''
								and peci:Person_Communication/peci:Address/peci:Address_Line_3 = '')">
							<xsl:value-of select="'NULL'"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:choose>
								<xsl:when test="peci:Person_Communication[not(@peci:isDeleted)]/peci:Address[not(@peci:isDeleted)]/peci:Address_Line_3[not(@peci:isDeleted)] != ''">
									<xsl:value-of select="peci:Person_Communication[not(@peci:isDeleted)]/peci:Address[not(@peci:isDeleted)]/peci:Address_Line_3[not(@peci:isDeleted)]"/>
								</xsl:when>
								<xsl:otherwise> </xsl:otherwise>
							</xsl:choose>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="Address4_temp">
			<xsl:for-each select="peci:Effective_Change[peci:Person_Communication/peci:Address]">
				<xsl:sort select="peci:Effective_Moment" order="descending"/>
				<xsl:if test="position() = 1">
					<xsl:choose>
						<xsl:when test="
								((peci:Person_Communication/@peci:isDeleted and not(peci:Person_Communication/@peci:isAdded) and not(peci:Person_Communication/@peci:isUpdated))
								or (peci:Person_Communication/peci:Address/@peci:isDeleted and not(peci:Person_Communication/peci:Address/@peci:isAdded) and not(peci:Person_Communication/peci:Address/@peci:isUpdated))
								or (peci:Person_Communication/peci:Address/peci:City/@peci:isDeleted and not(peci:Person_Communication/peci:Address/peci:City/@peci:isAdded) and not(peci:Person_Communication/peci:Address/peci:City/@peci:isUpdated)))
								or (count(peci:Person_Communication/peci:Address/peci:City) = 1
								and peci:Person_Communication/peci:Address/peci:City/@peci:priorValue != ''
								and peci:Person_Communication/peci:Address/peci:City = '')">
							<xsl:value-of select="'NULL'"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:choose>
								<xsl:when test="peci:Person_Communication[not(@peci:isDeleted)]/peci:Address[not(@peci:isDeleted)]/peci:City[not(@peci:isDeleted)] != ''">
									<xsl:value-of select="peci:Person_Communication[not(@peci:isDeleted)]/peci:Address[not(@peci:isDeleted)]/peci:City[not(@peci:isDeleted)]"/>
								</xsl:when>
								<xsl:otherwise> </xsl:otherwise>
							</xsl:choose>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="Postcode">
			<xsl:choose>
				<xsl:when test="
						((peci:Person_Communication/@peci:isDeleted and not(peci:Person_Communication/@peci:isAdded) and not(peci:Person_Communication/@peci:isUpdated))
						or (peci:Person_Communication/peci:Address/@peci:isDeleted and not(peci:Person_Communication/peci:Address/@peci:isAdded) and not(peci:Person_Communication/peci:Address/@peci:isUpdated))
						or (peci:Person_Communication/peci:Address/peci:Postal_Code/@peci:isDeleted and not(peci:Person_Communication/peci:Address/peci:Postal_Code/@peci:isAdded) and not(peci:Person_Communication/peci:Address/peci:Postal_Code/@peci:isUpdated)))
						or (count(peci:Person_Communication/peci:Address/peci:Postal_Code) = 1
						and peci:Person_Communication/peci:Address/peci:Postal_Code/@peci:priorValue != ''
						and peci:Person_Communication/peci:Address/peci:Postal_Code = '')">
					<xsl:value-of select="'NULL'"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="peci:Person_Communication[not(@peci:isDeleted)]/peci:Address[not(@peci:isDeleted)]/peci:Postal_Code[not(@peci:isDeleted)] != ''">
							<xsl:value-of select="peci:Person_Communication[not(@peci:isDeleted)]/peci:Address[not(@peci:isDeleted)]/peci:Postal_Code[not(@peci:isDeleted)]"/>
						</xsl:when>
						<xsl:otherwise/>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="Address1">
			<xsl:choose>
				<xsl:when test="$Address1_temp != '' and $Address1_temp != 'NULL'">
					<xsl:value-of select="$Address1_temp"/>
				</xsl:when>
				<xsl:when test="$Address1_temp = '' or $Address1_temp = 'NULL' and $Address2_temp != '' and $Address2_temp != 'NULL'">
					<xsl:value-of select="$Address2_temp"/>
				</xsl:when>
				<xsl:when test="$Address1_temp = '' or $Address1_temp = 'NULL' and ($Address2_temp = '' or $Address2_temp = 'NULL') and $Address3_temp != '' and $Address3_temp != 'NULL'">
					<xsl:value-of select="$Address3_temp"/>
				</xsl:when>
				<xsl:when test="$Address1_temp = '' or $Address1_temp = 'NULL' and ($Address2_temp = '' or $Address2_temp = 'NULL') and ($Address3_temp = '' or $Address3_temp = 'NULL') and $Address4_temp != '' and $Address4_temp != 'NULL'">
					<xsl:value-of select="$Address4_temp"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="'NULL'"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="Address2">
			<xsl:choose>
				<xsl:when test="$Address1_temp != '' and $Address1_temp != 'NULL' and $Address2_temp != '' and $Address2_temp != 'NULL'">
					<xsl:value-of select="$Address2_temp"/>
				</xsl:when>
				<xsl:when test="($Address1_temp != '' or $Address1_temp = 'NULL') and $Address3_temp != '' and $Address3_temp != 'NULL'">
					<xsl:value-of select="$Address3_temp"/>
				</xsl:when>
				<xsl:when test="($Address1_temp = '' or $Address1_temp = 'NULL') and ($Address3_temp = '' or $Address3_temp = 'NULL') and $Address4_temp != '' and $Address4_temp != 'NULL'">
					<xsl:value-of select="$Address4_temp"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="'NULL'"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="Address3">
			<xsl:choose>
				<xsl:when test="$Address1_temp != '' and $Address1_temp != 'NULL' and $Address2_temp != '' and $Address2_temp != 'NULL' and $Address3_temp != '' and $Address3_temp != 'NULL'">
					<xsl:value-of select="$Address3_temp"/>
				</xsl:when>
				<xsl:when test="($Address1_temp != '' or $Address1_temp = 'NULL' or $Address2_temp != '' or $Address2_temp = 'NULL') and $Address3_temp != '' and $Address3_temp != 'NULL'">
					<xsl:value-of select="$Address4_temp"/>
				</xsl:when>
				<xsl:otherwise/>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="Address4">
			<xsl:choose>
				<xsl:when test="$Address1_temp != '' and $Address1_temp != 'NULL' and $Address2_temp != '' and $Address2_temp != 'NULL' and $Address3_temp != '' and $Address3_temp != 'NULL' and $Address4_temp != '' and $Address4_temp != 'NULL'">
					<xsl:value-of select="$Address4_temp"/>
				</xsl:when>
				<xsl:otherwise/>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="DateOfBirth">
			<xsl:if test="peci:Effective_Change/peci:Personal/peci:Date_of_Birth">
				<xsl:for-each select="peci:Effective_Change[peci:Personal/peci:Date_of_Birth]">
					<xsl:sort select="peci:Effective_Moment" order="descending"/>
					<xsl:if test="position() = 1">
						<xsl:choose>
							<xsl:when test="
									((peci:Personal/@peci:isDeleted and not(peci:Personal/@peci:isAdded) and not(peci:Personal/@peci:isUpdated))
									or (peci:Personal/peci:Date_of_Birth/@peci:isDeleted and not(peci:Personal/peci:Date_of_Birth/@peci:isAdded) and not(peci:Personal/peci:Date_of_Birth/@peci:isUpdated)))
									or (count(peci:Personal/peci:Date_of_Birth) = 1
									and peci:Personal/peci:Date_of_Birth/@peci:priorValue != ''
									and peci:Personal/peci:Date_of_Birth = '')">
								<xsl:value-of select="'NULL'"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="format-date(xs:date(substring(peci:Personal[not(@peci:isDeleted)]/peci:Date_of_Birth[not(@peci:isDeleted)], 0, 11)), '[D01]/[M01]/[Y0001]')"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:if>
				</xsl:for-each>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="DateOfJoining">
			<xsl:if test="peci:Effective_Change/peci:Worker_Status/peci:Hire_Date">
				<xsl:for-each select="peci:Effective_Change[peci:Worker_Status/peci:Hire_Date]">
					<xsl:sort select="peci:Effective_Moment" order="descending"/>
					<xsl:if test="position() = 1">
						<xsl:choose>
							<xsl:when test="
									((peci:Worker_Status/@peci:isDeleted and not(peci:Worker_Status/@peci:isAdded) and not(peci:Worker_Status/@peci:isUpdated))
									or (peci:Worker_Status/peci:Hire_Date/@peci:isDeleted and not(peci:Worker_Status/peci:Hire_Date/@peci:isAdded) and not(peci:Worker_Status/peci:Hire_Date/@peci:isUpdated)))
									or (count(peci:Worker_Status/peci:Hire_Date) = 1
									and peci:Worker_Status/peci:Hire_Date/@peci:priorValue != ''
									and peci:Worker_Status/peci:Hire_Date = '')">
								<xsl:value-of select="'NULL'"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="format-date(xs:date(substring(peci:Worker_Status[not(@peci:isDeleted)]/peci:Hire_Date[not(@peci:isDeleted)], 0, 11)), '[D01]/[M01]/[Y0001]')"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:if>
				</xsl:for-each>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="Sex">
			<xsl:if test="peci:Effective_Change/peci:Personal/peci:Gender">
				<xsl:for-each select="peci:Effective_Change[peci:Personal/peci:Gender]">
					<xsl:sort select="peci:Effective_Moment" order="descending"/>
					<xsl:if test="position() = 1">
						<xsl:choose>
							<xsl:when test="
									((peci:Personal/@peci:isDeleted and not(peci:Personal/@peci:isAdded) and not(peci:Personal/@peci:isUpdated))
									or (peci:Personal/peci:Gender/@peci:isDeleted and not(peci:Personal/peci:Gender/@peci:isAdded) and not(peci:Personal/peci:Gender/@peci:isUpdated)))
									or (count(peci:Personal/peci:Gender) = 1
									and peci:Personal/peci:Gender/@peci:priorValue != ''
									and peci:Personal/peci:Gender = '')">
								<xsl:value-of select="'NULL'"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:choose>
									<xsl:when test="not(peci:Personal[not(@peci:isDeleted)]/peci:Gender[not(@peci:isDeleted)] = 'BLANK')">
										<xsl:value-of select="peci:Personal[not(@peci:isDeleted)]/peci:Gender[not(@peci:isDeleted)]"/>
									</xsl:when>
									<xsl:otherwise/>
								</xsl:choose>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:if>
				</xsl:for-each>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="PayrollNo">
			<xsl:value-of select="'FM3115'"/>
		</xsl:variable>
		<xsl:variable name="LeavingDate">
			<xsl:if test="peci:Effective_Change/peci:Worker_Status/peci:Termination_Date">
				<xsl:for-each select="peci:Effective_Change[peci:Worker_Status/peci:Termination_Date]">
					<xsl:sort select="peci:Effective_Moment" order="descending"/>
					<xsl:if test="position() = 1">
						<xsl:choose>
							<xsl:when test="
									((peci:Worker_Status/@peci:isDeleted and not(peci:Worker_Status/@peci:isAdded) and not(peci:Worker_Status/@peci:isUpdated))
									or (peci:Worker_Status/peci:Termination_Date/@peci:isDeleted and not(peci:Worker_Status/peci:Termination_Date/@peci:isAdded) and not(peci:Worker_Status/peci:Termination_Date/@peci:isUpdated)))
									or (count(peci:Worker_Status/peci:Termination_Date) = 1
									and peci:Worker_Status/peci:Termination_Date/@peci:priorValue != ''
									and peci:Worker_Status/peci:Termination_Date = '')">
								<xsl:value-of select="'NULL'"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="format-date(xs:date(substring(peci:Worker_Status[not(@peci:isDeleted)]/peci:Termination_Date[not(@peci:isDeleted)], 0, 11)), '[D01]/[M01]/[Y0001]')"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:if>
				</xsl:for-each>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="originalHireDate">
			<xsl:if test="peci:Effective_Change/peci:Worker_Status/peci:Original_Hire_Date">
				<xsl:for-each select="peci:Effective_Change[peci:Worker_Status/peci:Original_Hire_Date]">
					<xsl:sort select="peci:Effective_Moment" order="descending"/>
					<xsl:if test="position() = 1">
						<xsl:choose>
							<xsl:when test="
									((peci:Worker_Status/@peci:isDeleted and not(peci:Worker_Status/@peci:isAdded) and not(peci:Worker_Status/@peci:isUpdated))
									or (peci:Worker_Status/peci:Original_Hire_Date/@peci:isDeleted and not(peci:Worker_Status/peci:Original_Hire_Date/@peci:isAdded) and not(peci:Worker_Status/peci:Original_Hire_Date/@peci:isUpdated)))
									or (count(peci:Worker_Status/peci:Original_Hire_Date) = 1
									and peci:Worker_Status/peci:Original_Hire_Date/@peci:priorValue != ''
									and peci:Worker_Status/peci:Original_Hire_Date = '')">
								<xsl:value-of select="'NULL'"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="format-date(xs:date(substring(peci:Worker_Status[not(@peci:isDeleted)]/peci:Original_Hire_Date[not(@peci:isDeleted)], 0, 11)), '[D01]/[M01]/[Y0001]')"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:if>
				</xsl:for-each>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="Status">
			<xsl:choose>
				<xsl:when test="peci:Effective_Change/peci:Derived_Event_Code = 'TRM' and peci:Effective_Change/peci:Worker_Status/peci:Primary_Termination_Reason = 'DEATH'">
					<xsl:value-of select="'D'"/>
				</xsl:when>
				<xsl:when test="peci:Effective_Change/peci:Derived_Event_Code = 'TERM-R'">
					<xsl:value-of select="'N'"/>
				</xsl:when>
				<xsl:when test="peci:Effective_Change/peci:Derived_Event_Code = 'HIR' and $DateOfJoining != $originalHireDate">
					<xsl:value-of select="'R'"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="''"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="ReasonForLeaving">
			<xsl:if test="peci:Effective_Change/peci:Worker_Status/peci:Primary_Termination_Reason">
				<xsl:for-each select="peci:Effective_Change[peci:Worker_Status/peci:Primary_Termination_Reason]">
					<xsl:sort select="peci:Effective_Moment" order="descending"/>
					<xsl:if test="position() = 1">
						<xsl:choose>
							<xsl:when test="
									((peci:Worker_Status/@peci:isDeleted and not(peci:Worker_Status/@peci:isAdded) and not(peci:Worker_Status/@peci:isUpdated))
									or (peci:Worker_Status/peci:Primary_Termination_Reason/@peci:isDeleted and not(peci:Worker_Status/peci:Primary_Termination_Reason/@peci:isAdded) and not(peci:Worker_Status/peci:Primary_Termination_Reason/@peci:isUpdated)))
									or (count(peci:Worker_Status/peci:Primary_Termination_Reason) = 1
									and peci:Worker_Status/peci:Primary_Termination_Reason/@peci:priorValue != ''
									and peci:Worker_Status/peci:Primary_Termination_Reason = '')">
								<xsl:value-of select="'NULL'"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="peci:Worker_Status[not(@peci:isDeleted)]/peci:Primary_Termination_Reason[not(@peci:isDeleted)]"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:if>
				</xsl:for-each>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="Apprentice">
			<xsl:if test="peci:Effective_Change/peci:Position/peci:Worker_Type">
				<xsl:for-each select="peci:Effective_Change[peci:Position/peci:Worker_Type]">
					<xsl:sort select="peci:Effective_Moment" order="descending"/>
					<xsl:if test="position() = 1">
						<xsl:choose>
							<xsl:when test="
									((peci:Position/@peci:isDeleted and not(peci:Position/@peci:isAdded) and not(peci:Position/@peci:isUpdated))
									or (peci:Position/peci:Worker_Type/@peci:isDeleted and not(peci:Position/peci:Worker_Type/@peci:isAdded) and not(peci:Position/peci:Worker_Type/@peci:isUpdated)))
									or (count(peci:Position/peci:Worker_Type) = 1
									and peci:Position/peci:Worker_Type/@peci:priorValue != ''
									and peci:Position/peci:Worker_Type = '')">
								<xsl:value-of select="'NULL'"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:choose>
									<xsl:when test="count(peci:Position[not(@peci:isDeleted)]/peci:Worker_Type[not(@peci:isDeleted)]) > 1">
										<xsl:value-of select="substring-before(peci:Position[not(@peci:isDeleted) and not(peci:Position_End_Date)]/peci:Worker_Type[not(@peci:isDeleted)], '|')"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="substring-before(peci:Position[not(@peci:isDeleted)]/peci:Worker_Type[not(@peci:isDeleted)], '|')"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:if>
				</xsl:for-each>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="WorkEmailAddress">
			<xsl:if test="peci:Effective_Change/peci:Person_Communication/peci:Email[peci:Usage_Type = 'WORK']/peci:Email_Address">
				<xsl:for-each select="peci:Effective_Change[peci:Person_Communication/peci:Email[peci:Usage_Type = 'WORK']/peci:Email_Address]">
					<xsl:sort select="peci:Effective_Moment" order="descending"/>
					<xsl:if test="position() = 1">
						<xsl:choose>
							<xsl:when test="
									((peci:Person_Communication/@peci:isDeleted and not(peci:Person_Communication/@peci:isAdded) and not(peci:Person_Communication/@peci:isUpdated))
									or (peci:Person_Communication/peci:Email[peci:Usage_Type = 'WORK']/@peci:isDeleted and not(peci:Person_Communication/peci:Email[peci:Usage_Type = 'WORK']/@peci:isAdded) and not(peci:Person_Communication/peci:Email/@peci:isUpdated))
									or (peci:Person_Communication/peci:Email[peci:Usage_Type = 'WORK']/peci:Email_Address/@peci:isDeleted and not(peci:Person_Communication/peci:Email[peci:Usage_Type = 'WORK']/peci:Email_Address/@peci:isAdded) and not(peci:Person_Communication/peci:Email[peci:Usage_Type = 'WORK']/peci:Email_Address/@peci:isUpdated)))
									or (count(peci:Person_Communication/peci:Email[peci:Usage_Type = 'WORK']/peci:Email_Address) = 1
									and peci:Person_Communication/peci:Email[peci:Usage_Type = 'WORK']/peci:Email_Address/@peci:priorValue != ''
									and peci:Person_Communication/peci:Email[peci:Usage_Type = 'WORK']/peci:Email_Address = '')">
								<xsl:value-of select="'NULL'"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="peci:Person_Communication[not(@peci:isDeleted)]/peci:Email[not(@peci:isDeleted)][peci:Usage_Type = 'WORK']/peci:Email_Address[not(@peci:isDeleted)]"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:if>
				</xsl:for-each>
			</xsl:if>
		</xsl:variable>

		<xsl:variable name="EmployeeNoLength">
			<xsl:value-of select="11"/>
		</xsl:variable>
		<xsl:variable name="NINumberLength">
			<xsl:value-of select="9"/>
		</xsl:variable>
		<xsl:variable name="NewStarterLength">
			<xsl:value-of select="1"/>
		</xsl:variable>
		<xsl:variable name="PayGroupLength">
			<xsl:value-of select="5"/>
		</xsl:variable>
		<xsl:variable name="SurnameLength">
			<xsl:value-of select="20"/>
		</xsl:variable>
		<xsl:variable name="Forename1Length">
			<xsl:value-of select="15"/>
		</xsl:variable>
		<xsl:variable name="Forename2Length">
			<xsl:value-of select="15"/>
		</xsl:variable>
		<xsl:variable name="MaritalStatusLength">
			<xsl:value-of select="1"/>
		</xsl:variable>
		<xsl:variable name="KnownAsLength">
			<xsl:value-of select="30"/>
		</xsl:variable>
		<xsl:variable name="TitleLength">
			<xsl:value-of select="6"/>
		</xsl:variable>
		<xsl:variable name="PostcodeLength">
			<xsl:value-of select="10"/>
		</xsl:variable>
		<xsl:variable name="Address1Length">
			<xsl:value-of select="30"/>
		</xsl:variable>
		<xsl:variable name="Address2Length">
			<xsl:value-of select="30"/>
		</xsl:variable>
		<xsl:variable name="Address3Length">
			<xsl:value-of select="30"/>
		</xsl:variable>
		<xsl:variable name="Address4Length">
			<xsl:value-of select="30"/>
		</xsl:variable>
		<xsl:variable name="DateOfBirthLength">
			<xsl:value-of select="10"/>
		</xsl:variable>
		<xsl:variable name="DateOfJoiningLength">
			<xsl:value-of select="10"/>
		</xsl:variable>
		<xsl:variable name="SexLength">
			<xsl:value-of select="1"/>
		</xsl:variable>
		<xsl:variable name="PayrollNoLength">
			<xsl:value-of select="6"/>
		</xsl:variable>
		<xsl:variable name="LeavingDateLength">
			<xsl:value-of select="10"/>
		</xsl:variable>
		<xsl:variable name="StatusLength">
			<xsl:value-of select="1"/>
		</xsl:variable>
		<xsl:variable name="ReasonForLeavingLength">
			<xsl:value-of select="5"/>
		</xsl:variable>
		<xsl:variable name="ApprenticeLength">
			<xsl:value-of select="1"/>
		</xsl:variable>
		<xsl:variable name="WorkEmailAddressLength">
			<xsl:value-of select="100"/>
		</xsl:variable>

		<Errors etv:omit="true">
			<EmployeeNo etv:class="notReqWithWarn" etv:maxLength="{$EmployeeNoLength}" etv:targetWID="{$WorkerWID}">
				<xsl:value-of select="$EmployeeNo"/>
			</EmployeeNo>
			<NINumber etv:class="notReqWithWarn" etv:maxLength="{$NINumberLength}" etv:targetWID="{$WorkerWID}">
				<xsl:value-of select="$NINumber"/>
			</NINumber>
			<NewStarter etv:class="notReqWithWarn" etv:maxLength="{$NewStarterLength}" etv:targetWID="{$WorkerWID}">
				<xsl:value-of select="$NewStarter"/>
			</NewStarter>
			<PayGroup etv:class="notReqWithWarn" etv:maxLength="{$PayGroupLength}" etv:targetWID="{$WorkerWID}">
				<xsl:value-of select="$PayGroup"/>
			</PayGroup>
			<Surname etv:class="notReqWithWarn" etv:maxLength="{$SurnameLength}" etv:targetWID="{$WorkerWID}">
				<xsl:value-of select="$Surname"/>
			</Surname>
			<Forename1 etv:class="notReqWithWarn" etv:maxLength="{$Forename1Length}" etv:targetWID="{$WorkerWID}">
				<xsl:value-of select="$Forename1"/>
			</Forename1>
			<Forename2 etv:class="notReqWithWarn" etv:maxLength="{$Forename2Length}" etv:targetWID="{$WorkerWID}">
				<xsl:value-of select="$Forename2"/>
			</Forename2>
			<MaritalStatus etv:class="notReqWithWarn" etv:maxLength="{$MaritalStatusLength}" etv:targetWID="{$WorkerWID}">
				<xsl:value-of select="$MaritalStatus"/>
			</MaritalStatus>
			<KnownAs etv:class="notReqWithWarn" etv:maxLength="{$KnownAsLength}" etv:targetWID="{$WorkerWID}">
				<xsl:value-of select="$KnownAs"/>
			</KnownAs>
			<Title etv:class="notReqWithWarn" etv:maxLength="{$TitleLength}" etv:targetWID="{$WorkerWID}">
				<xsl:value-of select="$Title"/>
			</Title>
			<Address1 etv:class="notReqWithWarn" etv:maxLength="{$Address1Length}" etv:targetWID="{$WorkerWID}">
				<xsl:value-of select="$Address1"/>
			</Address1>
			<Address2 etv:class="notReqWithWarn" etv:maxLength="{$Address2Length}" etv:targetWID="{$WorkerWID}">
				<xsl:value-of select="$Address2"/>
			</Address2>
			<Address3 etv:class="notReqWithWarn" etv:maxLength="{$Address3Length}" etv:targetWID="{$WorkerWID}">
				<xsl:value-of select="$Address3"/>
			</Address3>
			<Address4 etv:class="notReqWithWarn" etv:maxLength="{$Address4Length}" etv:targetWID="{$WorkerWID}">
				<xsl:value-of select="$Address4"/>
			</Address4>
			<Postcode etv:class="notReqWithWarn" etv:maxLength="{$PostcodeLength}" etv:targetWID="{$WorkerWID}">
				<xsl:value-of select="$Postcode"/>
			</Postcode>
			<DateOfBirth etv:class="notReqWithWarn" etv:maxLength="{$DateOfBirthLength}" etv:targetWID="{$WorkerWID}">
				<xsl:value-of select="$DateOfBirth"/>
			</DateOfBirth>
			<DateOfJoining etv:class="notReqWithWarn" etv:maxLength="{$DateOfJoiningLength}" etv:targetWID="{$WorkerWID}">
				<xsl:value-of select="$DateOfJoining"/>
			</DateOfJoining>
			<Sex etv:class="notReqWithWarn" etv:maxLength="{$SexLength}" etv:targetWID="{$WorkerWID}">
				<xsl:value-of select="$Sex"/>
			</Sex>
			<PayrollNo etv:class="notReqWithWarn" etv:maxLength="{$PayrollNoLength}" etv:targetWID="{$WorkerWID}">
				<xsl:value-of select="$DateOfJoining"/>
			</PayrollNo>
			<LeavingDate etv:class="notReqWithWarn" etv:maxLength="{$LeavingDateLength}" etv:targetWID="{$WorkerWID}">
				<xsl:value-of select="$LeavingDate"/>
			</LeavingDate>
			<Status etv:class="notReqWithWarn" etv:maxLength="{$StatusLength}" etv:targetWID="{$WorkerWID}">
				<xsl:value-of select="$Status"/>
			</Status>
			<ReasonForLeaving etv:class="notReqWithWarn" etv:maxLength="{$ReasonForLeavingLength}" etv:targetWID="{$WorkerWID}">
				<xsl:value-of select="$ReasonForLeaving"/>
			</ReasonForLeaving>
			<Apprentice etv:class="notReqWithWarn" etv:maxLength="{$ApprenticeLength}" etv:targetWID="{$WorkerWID}">
				<xsl:value-of select="$Apprentice"/>
			</Apprentice>
			<WorkEmailAddress etv:class="notReqWithWarn" etv:maxLength="{$WorkEmailAddressLength}" etv:targetWID="{$WorkerWID}">
				<xsl:value-of select="$WorkEmailAddress"/>
			</WorkEmailAddress>
		</Errors>

		<xsl:if test="1=1">
			
			<Employee>
				<xsl:if test="$EmployeeNo != ''">
					<xsl:attribute name="EmployeeNo">
						<xsl:value-of select="$EmployeeNo"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="$EffectiveDate != ''">
					<xsl:attribute name="EffectiveDate">
						<xsl:value-of select="$EffectiveDate"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="$NINumber != ''">
					<xsl:attribute name="NINumber">
						<xsl:value-of select="$NINumber"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="$NewStarter != ''">
					<xsl:attribute name="NewStarter">
						<xsl:value-of select="$NewStarter"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="$PayGroup != ''">
					<xsl:attribute name="PayGroup">
						<xsl:value-of select="$PayGroup"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="$Surname != ''">
					<xsl:attribute name="Surname">
						<xsl:value-of select="$Surname"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="$Forename1 != ''">
					<xsl:attribute name="Forename1">
						<xsl:value-of select="$Forename1"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="$Forename2 != ''">
					<xsl:attribute name="Forename2">
						<xsl:value-of select="$Forename2"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="$MaritalStatus != ''">
					<xsl:attribute name="MaritalStatus">
						<xsl:value-of select="$MaritalStatus"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="$KnownAs != ''">
					<xsl:attribute name="KnownAs">
						<xsl:value-of select="$KnownAs"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="$Title != ''">
					<xsl:attribute name="Title">
						<xsl:value-of select="$Title"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="$Address1 != ''">
					<xsl:attribute name="Address1">
						<xsl:value-of select="$Address1"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="$Address2 != ''">
					<xsl:attribute name="Address2">
						<xsl:value-of select="$Address2"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="$Address3 != ''">
					<xsl:attribute name="Address3">
						<xsl:value-of select="$Address3"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="$Address4 != ''">
					<xsl:attribute name="Address4">
						<xsl:value-of select="$Address4"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="$Postcode != ''">
					<xsl:attribute name="Postcode" etv:maxLength="10">
						<xsl:value-of select="$Postcode"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="$DateOfBirth != ''">
					<xsl:attribute name="DateOfBirth">
						<xsl:value-of select="$DateOfBirth"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="$DateOfJoining != ''">
					<xsl:attribute name="DateOfJoining">
						<xsl:value-of select="$DateOfJoining"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="$Sex != ''">
					<xsl:attribute name="Sex">
						<xsl:value-of select="$Sex"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="$PayrollNo != ''">
					<xsl:attribute name="PayrollNo">
						<xsl:value-of select="$PayrollNo"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="$LeavingDate != ''">
					<xsl:attribute name="LeavingDate">
						<xsl:value-of select="$LeavingDate"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="$Status != ''">
					<xsl:attribute name="Status">
						<xsl:value-of select="$Status"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="$ReasonForLeaving != ''">
					<xsl:attribute name="ReasonForLeaving">
						<xsl:value-of select="$ReasonForLeaving"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="$Apprentice != ''">
					<xsl:attribute name="Apprentice">
						<xsl:value-of select="$Apprentice"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="$WorkEmailAddress != ''">
					<xsl:attribute name="WorkEmailAddress">
						<xsl:value-of select="$WorkEmailAddress"/>
					</xsl:attribute>
				</xsl:if>
	
				<!-- EEAbsenceDetail -->
				<xsl:for-each select="peci:Effective_Change/peci:Time_Off_Earnings_and_Deductions[contains(peci:External_Payroll_Code, 'EEABS')]">
					<xsl:sort select="../peci:Effective_Moment" order="descending"/>
					<xsl:sort select="peci:External_Payroll_Code" order="ascending"/>
					<xsl:if test="not(../following-sibling::*/peci:Time_Off_Earnings_and_Deductions/peci:External_Payroll_Code = peci:External_Payroll_Code)">
						<xsl:variable name="Action">
							<xsl:choose>
								<xsl:when test="@peci:isUpdated = '1'">
									<xsl:value-of select="'U'"/>
								</xsl:when>
								<xsl:when test="@peci:isAdded = '1'">
									<xsl:value-of select="'I'"/>
								</xsl:when>
								<xsl:when test="@peci:isDeleted = '1'">
									<xsl:value-of select="'D'"/>
								</xsl:when>
							</xsl:choose>
						</xsl:variable>
						<xsl:variable name="EndDate">
							<xsl:if test="peci:Grouped_Time_Off_Entry/peci:Leave_End_Date">
								<xsl:value-of select="format-date(xs:date(substring(peci:Grouped_Time_Off_Entry/peci:Leave_End_Date, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
							</xsl:if>
						</xsl:variable>
						<xsl:variable name="StartDate">
							<xsl:if test="peci:Grouped_Time_Off_Entry/peci:Leave_Start_Date">
								<xsl:choose>
									<xsl:when test="peci:Grouped_Time_Off_Entry/peci:Leave_Start_Date/@peci:priorValue != ''">
										<xsl:value-of select="format-date(xs:date(substring(peci:Grouped_Time_Off_Entry/peci:Leave_Start_Date/@peci:priorValue, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="format-date(xs:date(substring(peci:Grouped_Time_Off_Entry/peci:Leave_Start_Date, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:if>
						</xsl:variable>
						<xsl:variable name="IllnessCode">
							<xsl:value-of select="'0000'"/>
						</xsl:variable>
						<xsl:variable name="AbsenceType">
							<xsl:if test="peci:Grouped_Time_Off_Entry/peci:External_Payroll_Code">
								<xsl:choose>
									<xsl:when test="contains(peci:External_Payroll_Code, ':')">
										<xsl:choose>
											<xsl:when test="contains(peci:External_Payroll_Code, '_')">
												<xsl:value-of select="substring-before(peci:External_Payroll_Code, '_')"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="peci:External_Payroll_Code"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="peci:External_Payroll_Code"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:if>
						</xsl:variable>
						<xsl:variable name="NewStartDate">
							<xsl:if test="peci:Grouped_Time_Off_Entry/peci:Leave_Start_Date/@peci:priorValue != ''">
								<xsl:value-of select="format-date(xs:date(substring(peci:Grouped_Time_Off_Entry/peci:Leave_Start_Date, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
							</xsl:if>
						</xsl:variable>
	
						<xsl:variable name="ActionLength">
							<xsl:value-of select="1"/>
						</xsl:variable>
						<xsl:variable name="EndDateLength">
							<xsl:value-of select="10"/>
						</xsl:variable>
						<xsl:variable name="StartDateLength">
							<xsl:value-of select="10"/>
						</xsl:variable>
						<xsl:variable name="IllnessCodeLength">
							<xsl:value-of select="5"/>
						</xsl:variable>
						<xsl:variable name="AbsenceTypeLength">
							<xsl:value-of select="5"/>
						</xsl:variable>
						<xsl:variable name="NewStartDateLength">
							<xsl:value-of select="10"/>
						</xsl:variable>
	
						<Errors etv:omit="true">
							<Action etv:class="notReqWithWarn" etv:maxLength="{$ActionLength}" etv:targetWID="{$WorkerWID}">
								<xsl:value-of select="$Action"/>
							</Action>
							<EndDate etv:class="notReqWithWarn" etv:maxLength="{$EndDateLength}" etv:targetWID="{$WorkerWID}">
								<xsl:value-of select="$EndDate"/>
							</EndDate>
							<StartDate etv:class="notReqWithWarn" etv:maxLength="{$StartDateLength}" etv:targetWID="{$WorkerWID}">
								<xsl:value-of select="$StartDate"/>
							</StartDate>
							<IllnessCode etv:class="notReqWithWarn" etv:maxLength="{$IllnessCodeLength}" etv:targetWID="{$WorkerWID}">
								<xsl:value-of select="$IllnessCode"/>
							</IllnessCode>
							<AbsenceType etv:class="notReqWithWarn" etv:maxLength="{$AbsenceTypeLength}" etv:targetWID="{$WorkerWID}">
								<xsl:value-of select="$AbsenceType"/>
							</AbsenceType>
							<NewStartDate etv:class="notReqWithWarn" etv:maxLength="{$NewStartDateLength}" etv:targetWID="{$WorkerWID}">
								<xsl:value-of select="$NewStartDate"/>
							</NewStartDate>
						</Errors>
						<xsl:if test="1=1">
							<EEAbsenceDetail>
								<xsl:if test="$Action != ''">
									<xsl:attribute name="Action" etv:maxLength="1">
										<xsl:value-of select="$Action"/>
									</xsl:attribute>
								</xsl:if>
								<xsl:if test="$EndDate != ''">
									<xsl:attribute name="EndDate">
										<xsl:value-of select="$EndDate"/>
									</xsl:attribute>
								</xsl:if>
								<xsl:if test="$StartDate != ''">
									<xsl:attribute name="StartDate">
										<xsl:value-of select="$StartDate"/>
									</xsl:attribute>
								</xsl:if>
								<xsl:if test="$IllnessCode != ''">
									<xsl:attribute name="IllnessCode">
										<xsl:value-of select="$IllnessCode"/>
									</xsl:attribute>
								</xsl:if>
								<xsl:if test="$AbsenceType != ''">
									<xsl:attribute name="AbsenceType">
										<xsl:value-of select="$AbsenceType"/>
									</xsl:attribute>
								</xsl:if>
								<xsl:if test="$NewStartDate != ''">
									<xsl:attribute name="NewStartDate">
										<xsl:value-of select="$NewStartDate"/>
									</xsl:attribute>
								</xsl:if>
							</EEAbsenceDetail>
						</xsl:if>
					</xsl:if>
				</xsl:for-each>
				<xsl:for-each select="peci:Effective_Change/peci:Leave_of_Absence[contains(peci:Leave_of_Absence_Type, 'EEABSENCEDETAIL')]">
					<xsl:sort select="../peci:Effective_Moment" order="descending"/>
					<xsl:sort select="peci:Leave_of_Absence_Type" order="ascending"/>
					<xsl:if test="not(../following-sibling::*/peci:Leave_of_Absence/peci:Leave_of_Absence_Type = peci:Leave_of_Absence_Type)">
						<xsl:variable name="Action">
							<xsl:choose>
								<xsl:when test="@peci:isUpdated = '1'">
									<xsl:value-of select="'U'"/>
								</xsl:when>
								<xsl:when test="@peci:isAdded = '1'">
									<xsl:value-of select="'I'"/>
								</xsl:when>
								<xsl:when test="@peci:isDeleted = '1'">
									<xsl:value-of select="'D'"/>
								</xsl:when>
							</xsl:choose>
						</xsl:variable>
						<xsl:variable name="EndDate">
							<xsl:if test="peci:Leave_End_Date">
								<xsl:value-of select="format-date(xs:date(substring(peci:Leave_End_Date, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
							</xsl:if>
						</xsl:variable>
						<xsl:variable name="StartDate">
							<xsl:if test="peci:Leave_Start_Date">
								<xsl:choose>
									<xsl:when test="peci:Leave_Start_Date/@peci:priorValue != ''">
										<xsl:value-of select="format-date(xs:date(substring(peci:Leave_Start_Date/@peci:priorValue, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="format-date(xs:date(substring(peci:Leave_Start_Date, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:if>
						</xsl:variable>
						<xsl:variable name="IllnessCode">
							<xsl:value-of select="'0000'"/>
						</xsl:variable>
						<xsl:variable name="AbsenceType">
							<xsl:if test="peci:Leave_of_Absence_Type">
								<xsl:value-of select="substring-after(peci:Leave_of_Absence_Type, '_')"/>
							</xsl:if>
						</xsl:variable>
						<xsl:variable name="NewStartDate">
							<xsl:if test="peci:Leave_Start_Date/@peci:priorValue != ''">
								<xsl:value-of select="format-date(xs:date(substring(peci:Leave_Start_Date, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
							</xsl:if>
						</xsl:variable>
	
						<xsl:variable name="ActionLength">
							<xsl:value-of select="1"/>
						</xsl:variable>
						<xsl:variable name="EndDateLength">
							<xsl:value-of select="10"/>
						</xsl:variable>
						<xsl:variable name="StartDateLength">
							<xsl:value-of select="10"/>
						</xsl:variable>
						<xsl:variable name="IllnessCodeLength">
							<xsl:value-of select="5"/>
						</xsl:variable>
						<xsl:variable name="AbsenceTypeLength">
							<xsl:value-of select="5"/>
						</xsl:variable>
						<xsl:variable name="NewStartDateLength">
							<xsl:value-of select="10"/>
						</xsl:variable>
	
						<Errors etv:omit="true">
							<Action etv:class="notReqWithWarn" etv:maxLength="{$ActionLength}" etv:targetWID="{$WorkerWID}">
								<xsl:value-of select="$Action"/>
							</Action>
							<EndDate etv:class="notReqWithWarn" etv:maxLength="{$EndDateLength}" etv:targetWID="{$WorkerWID}">
								<xsl:value-of select="$EndDate"/>
							</EndDate>
							<StartDate etv:class="notReqWithWarn" etv:maxLength="{$StartDateLength}" etv:targetWID="{$WorkerWID}">
								<xsl:value-of select="$StartDate"/>
							</StartDate>
							<IllnessCode etv:class="notReqWithWarn" etv:maxLength="{$IllnessCodeLength}" etv:targetWID="{$WorkerWID}">
								<xsl:value-of select="$IllnessCode"/>
							</IllnessCode>
							<AbsenceType etv:class="notReqWithWarn" etv:maxLength="{$AbsenceTypeLength}" etv:targetWID="{$WorkerWID}">
								<xsl:value-of select="$AbsenceType"/>
							</AbsenceType>
							<NewStartDate etv:class="notReqWithWarn" etv:maxLength="{$NewStartDateLength}" etv:targetWID="{$WorkerWID}">
								<xsl:value-of select="$NewStartDate"/>
							</NewStartDate>
						</Errors>
	
						<xsl:if test="1=1">
							<EEAbsenceDetail>
								<xsl:if test="$Action != ''">
									<xsl:attribute name="Action" etv:maxLength="1">
										<xsl:value-of select="$Action"/>
									</xsl:attribute>
								</xsl:if>
								<xsl:if test="$EndDate != ''">
									<xsl:attribute name="EndDate">
										<xsl:value-of select="$EndDate"/>
									</xsl:attribute>
								</xsl:if>
								<xsl:if test="$StartDate != ''">
									<xsl:attribute name="StartDate">
										<xsl:value-of select="$StartDate"/>
									</xsl:attribute>
								</xsl:if>
								<xsl:if test="$IllnessCode != ''">
									<xsl:attribute name="IllnessCode">
										<xsl:value-of select="$IllnessCode"/>
									</xsl:attribute>
								</xsl:if>
								<xsl:if test="$AbsenceType != ''">
									<xsl:attribute name="AbsenceType">
										<xsl:value-of select="$AbsenceType"/>
									</xsl:attribute>
								</xsl:if>
								<xsl:if test="$NewStartDate != ''">
									<xsl:attribute name="NewStartDate">
										<xsl:value-of select="$NewStartDate"/>
									</xsl:attribute>
								</xsl:if>
							</EEAbsenceDetail>
						</xsl:if>
					</xsl:if>
				</xsl:for-each>
	
				<!-- EEBankDetail -->
				<xsl:if test="count(peci:Effective_Change/peci:Payment_Election[not(@peci:isDeleted)]) > 0">
					<xsl:for-each select="peci:Effective_Change/peci:Payment_Election[not(@peci:isDeleted)]">
						<xsl:sort select="../peci:Effective_Moment" order="descending"/>
						<xsl:sort select="peci:Order" order="ascending"/>
						<xsl:if test="not(../following-sibling::*/peci:Payment_Election/peci:Order = peci:Order)">
							<xsl:variable name="AccountOccurence">
								<xsl:if test="peci:Order">
									<xsl:value-of select="peci:Order"/>
								</xsl:if>
							</xsl:variable>
							<xsl:variable name="MethodOfPayment">
								<xsl:value-of select="'2'"/>
							</xsl:variable>
							<xsl:variable name="SortCode">
								<xsl:if test="peci:Bank_ID">
									<xsl:value-of select="peci:Bank_ID"/>
								</xsl:if>
							</xsl:variable>
							<xsl:variable name="AccountNo">
								<xsl:if test="peci:Account_Number">
									<xsl:value-of select="peci:Account_Number"/>
								</xsl:if>
							</xsl:variable>
							<xsl:variable name="AccountRef">
								<xsl:if test="peci:Roll_Number">
									<xsl:value-of select="peci:Roll_Number"/>
								</xsl:if>
							</xsl:variable>
							<xsl:variable name="Total_Base_Pay">
								<xsl:for-each select="../../peci:Effective_Change[peci:Compensation/peci:Compensation_Summary_in_Annualized_Frequency/peci:Total_Base_Pay != '']">
									<xsl:sort select="peci:Effective_Moment" order="descending"/>
									<xsl:if test="position() = 1">
										<xsl:value-of select="peci:Compensation/peci:Compensation_Summary_in_Annualized_Frequency/peci:Total_Base_Pay"/>
									</xsl:if>
								</xsl:for-each>
							</xsl:variable>
							<xsl:variable name="Amount">
								<xsl:if test="peci:Order != '1'">
									<xsl:choose>
										<xsl:when test="peci:Distribution_Percentage != '' and peci:Distribution_Percentage != '1'">
											<xsl:value-of select="peci:Distribution_Percentage * $Total_Base_Pay"/>
										</xsl:when>
										<xsl:when test="Distribution_Balance != '' and Distribution_Balance != '1'">
											<xsl:value-of select="peci:Distribution_Balance"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="$Total_Base_Pay"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:if>
							</xsl:variable>
	
							<xsl:variable name="AccountOccurenceLength">
								<xsl:value-of select="1"/>
							</xsl:variable>
							<xsl:variable name="MethodOfPaymentLength">
								<xsl:value-of select="1"/>
							</xsl:variable>
							<xsl:variable name="SortCodeLength">
								<xsl:value-of select="6"/>
							</xsl:variable>
							<xsl:variable name="AccountNoLength">
								<xsl:value-of select="10"/>
							</xsl:variable>
							<xsl:variable name="AccountRefLength">
								<xsl:value-of select="18"/>
							</xsl:variable>
							<xsl:variable name="AmountLength">
								<xsl:value-of select="1000"/>
							</xsl:variable>
	
							<Errors etv:omit="true">
								<AccountOccurence etv:class="notReqWithWarn" etv:maxLength="{$AccountOccurenceLength}" etv:targetWID="{$WorkerWID}">
									<xsl:value-of select="$AccountOccurence"/>
								</AccountOccurence>
								<MethodOfPayment etv:class="notReqWithWarn" etv:maxLength="{$MethodOfPaymentLength}" etv:targetWID="{$WorkerWID}">
									<xsl:value-of select="$MethodOfPayment"/>
								</MethodOfPayment>
								<SortCode etv:class="notReqWithWarn" etv:maxLength="{$SortCodeLength}" etv:targetWID="{$WorkerWID}">
									<xsl:value-of select="$SortCode"/>
								</SortCode>
								<AccountNo etv:class="notReqWithWarn" etv:maxLength="{$AccountNoLength}" etv:targetWID="{$WorkerWID}">
									<xsl:value-of select="$AccountNo"/>
								</AccountNo>
								<AccountRef etv:class="notReqWithWarn" etv:maxLength="{$AccountRefLength}" etv:targetWID="{$WorkerWID}">
									<xsl:value-of select="$AccountRef"/>
								</AccountRef>
								<Amount etv:class="notReqWithWarn" etv:maxLength="{$AmountLength}" etv:targetWID="{$WorkerWID}">
									<xsl:value-of select="$Amount"/>
								</Amount>
							</Errors>
	
							<xsl:if test="1=1">
								<EEBankDetail>
									<xsl:if test="$AccountOccurence != ''">
										<xsl:attribute name="AccountOccurence" etv:maxLength="1">
											<xsl:value-of select="$AccountOccurence"/>
										</xsl:attribute>
									</xsl:if>
									<xsl:if test="$MethodOfPayment != ''">
										<xsl:attribute name="MethodOfPayment">
											<xsl:value-of select="$MethodOfPayment"/>
										</xsl:attribute>
									</xsl:if>
									<xsl:if test="$SortCode != ''">
										<xsl:attribute name="SortCode">
											<xsl:value-of select="$SortCode"/>
										</xsl:attribute>
									</xsl:if>
									<xsl:if test="$AccountNo != ''">
										<xsl:attribute name="AccountNo">
											<xsl:value-of select="$AccountNo"/>
										</xsl:attribute>
									</xsl:if>
									<xsl:if test="$AccountRef != ''">
										<xsl:attribute name="AccountRef">
											<xsl:value-of select="$AccountRef"/>
										</xsl:attribute>
									</xsl:if>
									<xsl:if test="$Amount != ''">
										<xsl:attribute name="Amount">
											<xsl:value-of select="$Amount"/>
										</xsl:attribute>
									</xsl:if>
								</EEBankDetail>
							</xsl:if>
						</xsl:if>
					</xsl:for-each>
				</xsl:if>
				<!-- EEPSPayChange -->
				<xsl:variable name="EffectiveDate">
					<xsl:if test="peci:Effective_Change/peci:Additional_Information/ptdf:Compensation_Change_Effective_Date">
						<xsl:for-each select="peci:Effective_Change[peci:Additional_Information/ptdf:Compensation_Change_Effective_Date]">
							<xsl:sort select="peci:Effective_Moment" order="descending"/>
							<xsl:if test="position() = 1">
								<xsl:choose>
									<xsl:when test="
											((peci:Additional_Information/@peci:isDeleted and not(peci:Additional_Information/@peci:isAdded) and not(peci:Additional_Information/@peci:isUpdated))
											or (peci:Additional_Information/ptdf:Compensation_Change_Effective_Date/@peci:isDeleted and not(peci:Additional_Information/ptdf:Compensation_Change_Effective_Date/@peci:isAdded) and not(peci:Additional_Information/ptdf:Compensation_Change_Effective_Date/@peci:isUpdated)))
											or (count(peci:Additional_Information/ptdf:Compensation_Change_Effective_Date) = 1
											and peci:Additional_Information/ptdf:Compensation_Change_Effective_Date/@peci:priorValue != ''
											and peci:Additional_Information/ptdf:Compensation_Change_Effective_Date = '')">
										<xsl:value-of select="'NULL'"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="format-date(xs:date(substring(peci:Additional_Information[not(@peci:isDeleted)]/ptdf:Compensation_Change_Effective_Date[not(@peci:isDeleted)], 0, 11)), '[D01]/[M01]/[Y0001]')"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:if>
						</xsl:for-each>
					</xsl:if>
				</xsl:variable>
				<xsl:variable name="PayGroupID">
					<xsl:for-each select="peci:Effective_Change[peci:Position/peci:Position_Time_Type]">
						<xsl:sort select="peci:Effective_Moment" order="descending"/>
						<xsl:if test="position() = 1">
							<xsl:choose>
								<xsl:when test="
										((peci:Position/@peci:isDeleted and not(peci:Position/@peci:isAdded) and not(peci:Position/@peci:isUpdated))
										or (peci:Position/peci:Position_Time_Type/@peci:isDeleted and not(peci:Position/peci:Position_Time_Type/@peci:isAdded) and not(peci:Position/peci:Position_Time_Type/@peci:isUpdated)))
										or (count(peci:Position/peci:Position_Time_Type) = 1
										and peci:Position/peci:Position_Time_Type/@peci:priorValue != ''
										and peci:Position/peci:Position_Time_Type = '')">
									<xsl:value-of select="'NULL'"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:choose>
										<xsl:when test="count(peci:Position[not(@peci:isDeleted)]/peci:Position_Time_Type[not(@peci:isDeleted)]) > 1">
											<xsl:choose>
												<xsl:when test="peci:Position[not(@peci:isDeleted) and not(peci:Position_End_Date)]/peci:Position_Time_Type[not(@peci:isDeleted)] = 'Part_time'">
													<xsl:value-of select="'06'"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="'05'"/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:when>
										<xsl:otherwise>
											<xsl:choose>
												<xsl:when test="peci:Position[not(@peci:isDeleted)]/peci:Position_Time_Type[not(@peci:isDeleted)] = 'Part_time'">
													<xsl:value-of select="'06'"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="'05'"/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:if>
					</xsl:for-each>
				</xsl:variable>
				<xsl:variable name="GradeId">
					<xsl:if test="peci:Effective_Change/peci:Additional_Information/ptdf:Job_Level_Name">
						<xsl:for-each select="peci:Effective_Change[peci:Additional_Information/ptdf:Job_Level_Name]">
							<xsl:sort select="peci:Effective_Moment" order="descending"/>
							<xsl:if test="position() = 1">
								<xsl:choose>
									<xsl:when test="
											((peci:Additional_Information/@peci:isDeleted and not(peci:Additional_Information/@peci:isAdded) and not(peci:Additional_Information/@peci:isUpdated))
											or (peci:Additional_Information/ptdf:Job_Level_Name/@peci:isDeleted and not(peci:Additional_Information/ptdf:Job_Level_Name/@peci:isAdded) and not(peci:Additional_Information/ptdf:Job_Level_Name/@peci:isUpdated)))
											or (count(peci:Additional_Information/ptdf:Job_Level_Name) = 1
											and peci:Additional_Information/ptdf:Job_Level_Name/@peci:priorValue != ''
											and peci:Additional_Information/ptdf:Job_Level_Name = '')">
										<xsl:value-of select="'NULL'"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="peci:Additional_Information[not(@peci:isDeleted)]/ptdf:Job_Level_Name[not(@peci:isDeleted)]"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:if>
						</xsl:for-each>
					</xsl:if>
				</xsl:variable>
				<xsl:variable name="GradeSubCode">
					<xsl:if test="peci:Effective_Change/peci:Additional_Information/ptdf:Job_Level_Name">
						<xsl:for-each select="peci:Effective_Change[peci:Additional_Information/ptdf:Job_Level_Name]">
							<xsl:sort select="peci:Effective_Moment" order="descending"/>
							<xsl:if test="position() = 1">
								<xsl:choose>
									<xsl:when test="
											((peci:Additional_Information/@peci:isDeleted and not(peci:Additional_Information/@peci:isAdded) and not(peci:Additional_Information/@peci:isUpdated))
											or (peci:Additional_Information/ptdf:Job_Level_Name/@peci:isDeleted and not(peci:Additional_Information/ptdf:Job_Level_Name/@peci:isAdded) and not(peci:Additional_Information/ptdf:Job_Level_Name/@peci:isUpdated)))
											or (count(peci:Additional_Information/ptdf:Job_Level_Name) = 1
											and peci:Additional_Information/ptdf:Job_Level_Name/@peci:priorValue != ''
											and peci:Additional_Information/ptdf:Job_Level_Name = '')">
										<xsl:value-of select="'NULL'"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="'00'"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:if>
						</xsl:for-each>
					</xsl:if>
				</xsl:variable>
				<xsl:variable name="ChangeType">
					<xsl:if test="peci:Effective_Change/peci:Compensation/peci:Compensation_Change_Reason">
						<xsl:for-each select="peci:Effective_Change[peci:Compensation/peci:Compensation_Change_Reason]">
							<xsl:sort select="peci:Effective_Moment" order="descending"/>
							<xsl:if test="position() = 1">
								<xsl:choose>
									<xsl:when test="
											((peci:Compensation/@peci:isDeleted and not(peci:Compensation/@peci:isAdded) and not(peci:Compensation/@peci:isUpdated))
											or (peci:Compensation/peci:Compensation_Change_Reason/@peci:isDeleted and not(peci:Compensation/peci:Compensation_Change_Reason/@peci:isAdded) and not(peci:Compensation/peci:Compensation_Change_Reason/@peci:isUpdated)))
											or (count(peci:Compensation/peci:Compensation_Change_Reason) = 1
											and peci:Compensation/peci:Compensation_Change_Reason/@peci:priorValue != ''
											and peci:Compensation/peci:Compensation_Change_Reason = '')">
										<xsl:value-of select="'NULL'"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="peci:Compensation[not(@peci:isDeleted)]/peci:Compensation_Change_Reason[not(@peci:isDeleted)]"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:if>
						</xsl:for-each>
					</xsl:if>
				</xsl:variable>
				<xsl:variable name="Salary">
					<xsl:if test="peci:Effective_Change/peci:Compensation/peci:Compensation_Summary_in_Annualized_Frequency/peci:Total_Base_Pay">
						<xsl:for-each select="peci:Effective_Change[peci:Compensation/peci:Compensation_Summary_in_Annualized_Frequency/peci:Total_Base_Pay]">
							<xsl:sort select="peci:Effective_Moment" order="descending"/>
							<xsl:if test="position() = 1">
								<xsl:choose>
									<xsl:when test="
											((peci:Compensation/@peci:isDeleted and not(peci:Compensation/@peci:isAdded) and not(peci:Compensation/@peci:isUpdated))
											or (peci:Compensation/peci:Compensation_Summary_in_Annualized_Frequency/@peci:isDeleted and not(peci:Compensation/peci:Compensation_Summary_in_Annualized_Frequency/@peci:isAdded) and not(peci:Compensation/peci:Compensation_Summary_in_Annualized_Frequency/@peci:isUpdated))
											or (peci:Compensation/peci:Compensation_Summary_in_Annualized_Frequency/peci:Total_Base_Pay/@peci:isDeleted and not(peci:Compensation/peci:Compensation_Summary_in_Annualized_Frequency/peci:Total_Base_Pay/@peci:isAdded) and not(peci:Compensation/peci:Compensation_Summary_in_Annualized_Frequency/peci:Total_Base_Pay/@peci:isUpdated)))
											or (count(peci:Compensation/peci:Compensation_Summary_in_Annualized_Frequency/peci:Total_Base_Pay) = 1
											and peci:Compensation/peci:Compensation_Summary_in_Annualized_Frequency/peci:Total_Base_Pay/@peci:priorValue != ''
											and peci:Compensation/peci:Compensation_Summary_in_Annualized_Frequency/peci:Total_Base_Pay = '')">
										<xsl:value-of select="'NULL'"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="peci:Compensation[not(@peci:isDeleted)]/peci:Compensation_Summary_in_Annualized_Frequency[not(@peci:isDeleted)]/peci:Total_Base_Pay[not(@peci:isDeleted)]"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:if>
						</xsl:for-each>
					</xsl:if>
				</xsl:variable>
				<xsl:variable name="Classification">
					<xsl:if test="peci:Effective_Change/peci:Position/peci:Worker_Type">
						<xsl:for-each select="peci:Effective_Change[peci:Position/peci:Worker_Type]">
							<xsl:sort select="peci:Effective_Moment" order="descending"/>
							<xsl:if test="position() = 1">
								<xsl:choose>
									<xsl:when test="
											((peci:Position/@peci:isDeleted and not(peci:Position/@peci:isAdded) and not(peci:Position/@peci:isUpdated))
											or (peci:Position/peci:Worker_Type/@peci:isDeleted and not(peci:Position/peci:Worker_Type/@peci:isAdded) and not(peci:Position/peci:Worker_Type/@peci:isUpdated)))
											or (count(peci:Position/peci:Worker_Type) = 1
											and peci:Position/peci:Worker_Type/@peci:priorValue != ''
											and peci:Position/peci:Worker_Type = '')">
										<xsl:value-of select="'NULL'"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:choose>
											<xsl:when test="count(peci:Position[not(@peci:isDeleted)]/peci:Worker_Type[not(@peci:isDeleted)]) > 1">
												<xsl:value-of select="substring-after(peci:Position[not(@peci:isDeleted) and not(peci:Position_End_Date)]/peci:Worker_Type[not(@peci:isDeleted)], '|')"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="substring-after(peci:Position[not(@peci:isDeleted)]/peci:Worker_Type[not(@peci:isDeleted)], '|')"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:if>
						</xsl:for-each>
					</xsl:if>
				</xsl:variable>
				<xsl:variable name="WeeklyHours">
					<xsl:for-each select="peci:Effective_Change[peci:Position/peci:Default_Weekly_Hours]">
						<xsl:sort select="peci:Effective_Moment" order="descending"/>
						<xsl:if test="position() = 1">
							<xsl:choose>
								<xsl:when test="
										((peci:Position/@peci:isDeleted and not(peci:Position/@peci:isAdded) and not(peci:Position/@peci:isUpdated))
										or (peci:Position/peci:Default_Weekly_Hours/@peci:isDeleted and not(peci:Position/peci:Default_Weekly_Hours/@peci:isAdded) and not(peci:Position/peci:Default_Weekly_Hours/@peci:isUpdated)))
										or (count(peci:Position/peci:Default_Weekly_Hours) = 1
										and peci:Position/peci:Default_Weekly_Hours/@peci:priorValue != ''
										and peci:Position/peci:Default_Weekly_Hours = '')">
									<xsl:value-of select="'NULL'"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:choose>
										<xsl:when test="count(peci:Position[not(@peci:isDeleted)]/peci:Default_Weekly_Hours[not(@peci:isDeleted)]) > 1">
											<xsl:value-of select="peci:Position[not(@peci:isDeleted) and not(peci:Position_End_Date)]/peci:Default_Weekly_Hours[not(@peci:isDeleted)]"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="peci:Position[not(@peci:isDeleted)]/peci:Default_Weekly_Hours[not(@peci:isDeleted)]"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:if>
					</xsl:for-each>
				</xsl:variable>
				<xsl:variable name="HoursPayable">
					<xsl:value-of select="$WeeklyHours"/>
				</xsl:variable>
				<xsl:variable name="WPMap">
					<WPMAP key="M, Tu, W" value="301"/>
					<WPMAP key="M, Tu, Th" value="302"/>
					<WPMAP key="M, Tu, F" value="303"/>
					<WPMAP key="M, W, Th" value="304"/>
					<WPMAP key="M, W, F" value="305"/>
					<WPMAP key="M, Th, F" value="306"/>
					<WPMAP key="Tu, W, Th" value="307"/>
					<WPMAP key="Tu, W, F" value="308"/>
					<WPMAP key="Tu, Th, F" value="309"/>
					<WPMAP key="W, Th, F" value="310"/>
					<WPMAP key="M, Tu, W, Th" value="401"/>
					<WPMAP key="M, Tu, W, F" value="402"/>
					<WPMAP key="M, Tu, Th, F" value="403"/>
					<WPMAP key="M, W, Th, F" value="404"/>
					<WPMAP key="Tu, W, Th, F" value="405"/>
					<WPMAP key="M - F" value="501"/>
				</xsl:variable>
				<xsl:variable name="WorkingPatternID_temp">
					<xsl:for-each select="peci:Effective_Change[peci:Additional_Information/ptdf:WorkingPatternID]">
						<xsl:sort select="peci:Effective_Moment" order="descending"/>
						<xsl:if test="position() = 1">
							<xsl:choose>
								<xsl:when test="
										((peci:Additional_Information/@peci:isDeleted and not(peci:Additional_Information/@peci:isAdded) and not(peci:Additional_Information/@peci:isUpdated))
										or (peci:Additional_Information/ptdf:WorkingPatternID/@peci:isDeleted and not(peci:Additional_Information/ptdf:WorkingPatternID/@peci:isAdded) and not(peci:Additional_Information/ptdf:WorkingPatternID/@peci:isUpdated)))
										or (count(peci:Additional_Information/ptdf:WorkingPatternID) = 1
										and peci:Additional_Information/ptdf:WorkingPatternID/@peci:priorValue != ''
										and peci:Additional_Information/ptdf:WorkingPatternID = '')">
									<xsl:value-of select="'NULL'"/>
								</xsl:when>
								<xsl:otherwise>
									<!-- Get value in brackets -->
									<xsl:value-of select="substring-before(substring-after(peci:Additional_Information[not(@peci:isDeleted)]/ptdf:WorkingPatternID[not(@peci:isDeleted)], '('), ')')"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:if>
					</xsl:for-each>
				</xsl:variable>
				<xsl:variable name="WorkingPatternID">
					<xsl:if test="$WorkingPatternID_temp != ''">
						<xsl:choose>
							<xsl:when test="substring-before(substring-after(node, '('), ')') = ''">
								<!-- DO THE MAPPING on the Working Pattern ID-->
								<xsl:value-of select="$WPMap/WPMAP[@key = $WorkingPatternID_temp]/@value"/>
							</xsl:when>
						</xsl:choose>
					</xsl:if>
				</xsl:variable>
				<xsl:variable name="OSPSchemeNo">
					<xsl:value-of select="'1'"/>
				</xsl:variable>
				<xsl:variable name="timeType">
					<xsl:for-each select="peci:Effective_Change[peci:Position/peci:Position_Time_Type]">
						<xsl:sort select="peci:Effective_Moment" order="descending"/>
						<xsl:if test="position() = 1">
							<xsl:choose>
								<xsl:when test="
										((peci:Position/@peci:isDeleted and not(peci:Position/@peci:isAdded) and not(peci:Position/@peci:isUpdated))
										or (peci:Position/peci:Position_Time_Type/@peci:isDeleted and not(peci:Position/peci:Position_Time_Type/@peci:isAdded) and not(peci:Position/peci:Position_Time_Type/@peci:isUpdated)))
										or (count(peci:Position/peci:Position_Time_Type) = 1
										and peci:Position/peci:Position_Time_Type/@peci:priorValue != ''
										and peci:Position/peci:Position_Time_Type = '')">
									<xsl:value-of select="'NULL'"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="peci:Position[not(@peci:isDeleted)]/peci:Position_Time_Type[not(@peci:isDeleted)]"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:if>
					</xsl:for-each>
				</xsl:variable>
				<xsl:variable name="RTIHoursInd">
					<xsl:if test="$timeType != ''">
						<xsl:choose>
							<xsl:when test="$timeType = 'Full_time'">
								<xsl:value-of select="'N'"/>
							</xsl:when>
							<xsl:when test="$timeType = 'Part_time'">
								<xsl:value-of select="'Y'"/>
							</xsl:when>
						</xsl:choose>
					</xsl:if>
				</xsl:variable>
				<xsl:variable name="MaxOTRateType">
					<xsl:if test="peci:Effective_Change/peci:Position/peci:Default_Weekly_Hours">
						<xsl:choose>
							<xsl:when test="$WeeklyHours = '36'">
								<xsl:value-of select="'I'"/>
							</xsl:when>
							<xsl:when test="$WeeklyHours = '37'">
								<xsl:value-of select="'N'"/>
							</xsl:when>
						</xsl:choose>
					</xsl:if>
				</xsl:variable>
				<xsl:variable name="LweightType">
					<xsl:if test="peci:Effective_Change/peci:Position/peci:Default_Weekly_Hours">
						<xsl:choose>
							<xsl:when test="$WeeklyHours = '36'">
								<xsl:value-of select="'I'"/>
							</xsl:when>
							<xsl:when test="$WeeklyHours = '37'">
								<xsl:value-of select="'N'"/>
							</xsl:when>
						</xsl:choose>
					</xsl:if>
				</xsl:variable>
	
				<xsl:variable name="EffectiveDateLength">
					<xsl:value-of select="10"/>
				</xsl:variable>
				<xsl:variable name="PayGroupIDLength">
					<xsl:value-of select="5"/>
				</xsl:variable>
				<xsl:variable name="GradeIdLength">
					<xsl:value-of select="6"/>
				</xsl:variable>
				<xsl:variable name="GradeSubCodeLength">
					<xsl:value-of select="2"/>
				</xsl:variable>
				<xsl:variable name="ChangeTypeLength">
					<xsl:value-of select="100"/>
				</xsl:variable>
				<xsl:variable name="SalaryLength">
					<xsl:value-of select="100"/>
				</xsl:variable>
				<xsl:variable name="ClassificationLength">
					<xsl:value-of select="5"/>
				</xsl:variable>
				<xsl:variable name="HoursPayableLength">
					<xsl:value-of select="100"/>
				</xsl:variable>
				<xsl:variable name="WorkingPatternIDLength">
					<xsl:value-of select="5"/>
				</xsl:variable>
				<xsl:variable name="OSPSchemeNoLength">
					<xsl:value-of select="7"/>
				</xsl:variable>
				<xsl:variable name="RTIHoursIndLength">
					<xsl:value-of select="1"/>
				</xsl:variable>
				<xsl:variable name="MaxOTRateTypeLength">
					<xsl:value-of select="100"/>
				</xsl:variable>
				<xsl:variable name="LweightTypeLength">
					<xsl:value-of select="100"/>
				</xsl:variable>
	
				<Errors etv:omit="true">
					<EffectiveDate etv:class="notReqWithWarn" etv:maxLength="{$EffectiveDateLength}" etv:targetWID="{$WorkerWID}">
						<xsl:value-of select="$EffectiveDate"/>
					</EffectiveDate>
					<PayGroupID etv:class="notReqWithWarn" etv:maxLength="{$PayGroupIDLength}" etv:targetWID="{$WorkerWID}">
						<xsl:value-of select="$PayGroupID"/>
					</PayGroupID>
					<GradeId etv:class="notReqWithWarn" etv:maxLength="{$GradeIdLength}" etv:targetWID="{$WorkerWID}">
						<xsl:value-of select="$GradeId"/>
					</GradeId>
					<GradeSubCode etv:class="notReqWithWarn" etv:maxLength="{$GradeSubCodeLength}" etv:targetWID="{$WorkerWID}">
						<xsl:value-of select="$GradeSubCode"/>
					</GradeSubCode>
					<ChangeType etv:class="notReqWithWarn" etv:maxLength="{$ChangeTypeLength}" etv:targetWID="{$WorkerWID}">
						<xsl:value-of select="$ChangeType"/>
					</ChangeType>
					<Salary etv:class="notReqWithWarn" etv:maxLength="{$SalaryLength}" etv:targetWID="{$WorkerWID}">
						<xsl:value-of select="$Salary"/>
					</Salary>
					<Classification etv:class="notReqWithWarn" etv:maxLength="{$ClassificationLength}" etv:targetWID="{$WorkerWID}">
						<xsl:value-of select="$Classification"/>
					</Classification>
					<HoursPayable etv:class="notReqWithWarn" etv:maxLength="{$HoursPayableLength}" etv:targetWID="{$WorkerWID}">
						<xsl:value-of select="$HoursPayable"/>
					</HoursPayable>
					<WorkingPatternID etv:class="notReqWithWarn" etv:maxLength="{$WorkingPatternIDLength}" etv:targetWID="{$WorkerWID}">
						<xsl:value-of select="$WorkingPatternID"/>
					</WorkingPatternID>
					<OSPSchemeNo etv:class="notReqWithWarn" etv:maxLength="{$OSPSchemeNoLength}" etv:targetWID="{$WorkerWID}">
						<xsl:value-of select="$OSPSchemeNo"/>
					</OSPSchemeNo>
					<RTIHoursInd etv:class="notReqWithWarn" etv:maxLength="{$RTIHoursIndLength}" etv:targetWID="{$WorkerWID}">
						<xsl:value-of select="$RTIHoursInd"/>
					</RTIHoursInd>
					<MaxOTRateType etv:class="notReqWithWarn" etv:maxLength="{$MaxOTRateTypeLength}" etv:targetWID="{$WorkerWID}">
						<xsl:value-of select="$MaxOTRateType"/>
					</MaxOTRateType>
					<LweightType etv:class="notReqWithWarn" etv:maxLength="{$LweightTypeLength}" etv:targetWID="{$WorkerWID}">
						<xsl:value-of select="$LweightType"/>
					</LweightType>
				</Errors>
				<!-- mandatory fields evaluated here --> 
				<xsl:if test="1=1">
					<EEPSPayChange>
						<xsl:if test="$EffectiveDate != ''">
							<xsl:attribute name="EffectiveDate">
								<xsl:value-of select="$EffectiveDate"/>
							</xsl:attribute>
						</xsl:if>
						<xsl:if test="$PayGroupID != ''">
							<xsl:attribute name="PayGroupID">
								<xsl:value-of select="$PayGroupID"/>
							</xsl:attribute>
						</xsl:if>
						<xsl:if test="$GradeId != ''">
							<xsl:attribute name="GradeId">
								<xsl:value-of select="$GradeId"/>
							</xsl:attribute>
						</xsl:if>
						<xsl:if test="$GradeSubCode != ''">
							<xsl:attribute name="GradeSubCode">
								<xsl:value-of select="$GradeSubCode"/>
							</xsl:attribute>
						</xsl:if>
						<xsl:if test="$ChangeType != ''">
							<xsl:attribute name="ChangeType">
								<xsl:value-of select="$ChangeType"/>
							</xsl:attribute>
						</xsl:if>
						<xsl:if test="$Salary != ''">
							<xsl:attribute name="Salary">
								<xsl:value-of select="$Salary"/>
							</xsl:attribute>
						</xsl:if>
						<xsl:if test="$Classification != ''">
							<xsl:attribute name="Classification">
								<xsl:value-of select="$Classification"/>
							</xsl:attribute>
						</xsl:if>
						<xsl:if test="$HoursPayable != ''">
							<xsl:attribute name="HoursPayable">
								<xsl:value-of select="$HoursPayable"/>
							</xsl:attribute>
						</xsl:if>
						<xsl:if test="$WorkingPatternID != ''">
							<xsl:attribute name="WorkingPatternID">
								<xsl:value-of select="$WorkingPatternID"/>
							</xsl:attribute>
						</xsl:if>
						<xsl:if test="$OSPSchemeNo != ''">
							<xsl:attribute name="OSPSchemeNo">
								<xsl:value-of select="$OSPSchemeNo"/>
							</xsl:attribute>
						</xsl:if>
						<xsl:if test="$RTIHoursInd != ''">
							<xsl:attribute name="RTIHoursInd">
								<xsl:value-of select="$RTIHoursInd"/>
							</xsl:attribute>
						</xsl:if>
						<xsl:if test="$MaxOTRateType != ''">
							<xsl:attribute name="MaxOTRateType">
								<xsl:value-of select="$MaxOTRateType"/>
							</xsl:attribute>
						</xsl:if>
						<xsl:if test="$LweightType != ''">
							<xsl:attribute name="LweightType">
								<xsl:value-of select="$LweightType"/>
							</xsl:attribute>
						</xsl:if>
					</EEPSPayChange>
				</xsl:if>
	
				<!-- EEPaymentElement - COMPENSATION-->
				<xsl:for-each select="peci:Effective_Change/peci:Compensation_Earnings_and_Deductions">
					<xsl:sort select="../peci:Effective_Moment" order="descending"/>
					<xsl:sort select="peci:External_Payroll_Code" order="ascending"/>
					<xsl:if test="not(../following-sibling::*/peci:Compensation_Earnings_and_Deductions/peci:External_Payroll_Code = peci:External_Payroll_Code)">
						<xsl:variable name="EffectiveDate">
							<xsl:choose>
								<xsl:when test="../peci:Effective_Moment != ''">
									<xsl:value-of select="format-date(xs:date(substring(../peci:Effective_Moment, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="''"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<xsl:variable name="Paycode">
							<xsl:if test="peci:External_Payroll_Code">
								<xsl:choose>
									<xsl:when test="contains(peci:External_Payroll_Code, ':')">
										<xsl:value-of select="substring-after(peci:External_Payroll_Code, ':')"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="peci:External_Payroll_Code"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:if>
						</xsl:variable>
						<xsl:variable name="Amount">
							<xsl:if test="peci:Amount">
								<xsl:value-of select="peci:Amount"/>
							</xsl:if>
						</xsl:variable>
						
						<xsl:variable name="EffectiveDateLength">
							<xsl:value-of select="10"/>
						</xsl:variable>
						<xsl:variable name="PaycodeLength">
							<xsl:value-of select="5"/>
						</xsl:variable>
						<xsl:variable name="AmountLength">
							<xsl:value-of select="100"/>
						</xsl:variable>
						
						<Errors etv:omit="true"> 
							<EffectiveDate etv:class="notReqWithWarn" etv:maxLength="{$EffectiveDateLength}" etv:targetWID="{$WorkerWID}"> 
								<xsl:value-of select="$EffectiveDate"/> 
							</EffectiveDate>
							<Paycode etv:class="notReqWithWarn" etv:maxLength="{$PaycodeLength}" etv:targetWID="{$WorkerWID}"> 
								<xsl:value-of select="$Paycode"/> 
							</Paycode>
							<Amount etv:class="notReqWithWarn" etv:maxLength="{$AmountLength}" etv:targetWID="{$WorkerWID}"> 
								<xsl:value-of select="$Amount"/> 
							</Amount>
						</Errors>
						
						<xsl:if test="1=1">
							<EEPaymentElement>
								<xsl:if test="$EffectiveDate != ''"> 
									<xsl:copy>
										<xsl:attribute name="EffectiveDate"> 
											<xsl:value-of select="$EffectiveDate"/> 
										</xsl:attribute>
									</xsl:copy>
								</xsl:if>
								<xsl:if test="$Paycode != ''"> 
									<xsl:copy>
										<xsl:attribute name="Paycode"> 
											<xsl:value-of select="$Paycode"/> 
										</xsl:attribute>
									</xsl:copy>
								</xsl:if>
								<xsl:choose>
									<xsl:when test="substring-before(peci:External_Payroll_Code, ':') = 'AnnualAmount'">
										<xsl:copy>
											<xsl:attribute name="AnnualAmount">
												<xsl:value-of select="$Amount"/>
											</xsl:attribute>
										</xsl:copy>
									</xsl:when>
									<xsl:when test="substring-before(peci:External_Payroll_Code, ':') = 'PeriodAmount'">
										<xsl:copy>
											<xsl:attribute name="PeriodAmount">
												<xsl:value-of select="$Amount"/>
											</xsl:attribute>
										</xsl:copy>
									</xsl:when>
									<xsl:otherwise/>
								</xsl:choose>
							</EEPaymentElement>
						</xsl:if>
					</xsl:if>
				</xsl:for-each>
				<!-- EEPaymentElement - BENEFITS -->
				<xsl:for-each select="peci:Effective_Change/peci:Benefits_Earnings_and_Deductions">
					<xsl:sort select="../peci:Effective_Moment" order="descending"/>
					<xsl:sort select="peci:External_Payroll_Code" order="ascending"/>
					<xsl:if test="not(../following-sibling::*/peci:Benefits_Earnings_and_Deductions/peci:External_Payroll_Code = peci:External_Payroll_Code)">
						<xsl:variable name="EffectiveDate">
							<xsl:choose>
								<xsl:when test="../peci:Effective_Moment != ''">
									<xsl:value-of select="format-date(xs:date(substring(../peci:Effective_Moment, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="''"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<xsl:variable name="Paycode">
							<xsl:if test="peci:External_Payroll_Code">
								<xsl:choose>
									<xsl:when test="contains(peci:External_Payroll_Code, ':')">
										<xsl:value-of select="substring-after(peci:External_Payroll_Code, ':')"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="peci:External_Payroll_Code"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:if>
						</xsl:variable>
						<xsl:variable name="PeriodAmount">
							<xsl:if test="peci:Amount">
								<xsl:value-of select="peci:Amount"/>
							</xsl:if>
						</xsl:variable>
						<xsl:variable name="CoverageAmount">
							<xsl:if test="peci:Coverage_Amount and (contains(peci:External_Payroll_Code, '368') or contains(peci:External_Payroll_Code, '510') or contains(peci:External_Payroll_Code, '525'))">
								<xsl:value-of select="peci:Coverage_Amount"/>
							</xsl:if>
						</xsl:variable>
						
						<xsl:variable name="EffectiveDateLength">
							<xsl:value-of select="10"/>
						</xsl:variable>
						<xsl:variable name="PaycodeLength">
							<xsl:value-of select="5"/>
						</xsl:variable>
						<xsl:variable name="PeriodAmountLength">
							<xsl:value-of select="100"/>
						</xsl:variable>
						<xsl:variable name="CoverageAmountLength">
							<xsl:value-of select="100"/>
						</xsl:variable>
						
						<Errors etv:omit="true"> 
							<EffectiveDate etv:class="notReqWithWarn" etv:maxLength="{$EffectiveDateLength}" etv:targetWID="{$WorkerWID}"> 
								<xsl:value-of select="$EffectiveDate"/>
							</EffectiveDate>
							<Paycode etv:class="notReqWithWarn" etv:maxLength="{$PaycodeLength}" etv:targetWID="{$WorkerWID}"> 
								<xsl:value-of select="$Paycode"/> 
							</Paycode>
							<PeriodAmount etv:class="notReqWithWarn" etv:maxLength="{$PeriodAmountLength}" etv:targetWID="{$WorkerWID}"> 
								<xsl:value-of select="$PeriodAmount"/> 
							</PeriodAmount>
							<CoverageAmount etv:class="notReqWithWarn" etv:maxLength="{$CoverageAmountLength}" etv:targetWID="{$WorkerWID}"> 
								<xsl:value-of select="$CoverageAmount"/> 
							</CoverageAmount>
						</Errors>
						
						<xsl:if test="1=1">
							<EEPaymentElement>
								<xsl:if test="$EffectiveDate != ''">
									 <xsl:attribute name="EffectiveDate">
										<xsl:value-of select="$EffectiveDate"/>
									</xsl:attribute>
								</xsl:if>
								<xsl:if test="$Paycode != ''">
									 <xsl:attribute name="Paycode"> 
										<xsl:value-of select="$Paycode"/> 
									</xsl:attribute>
								</xsl:if>
								<xsl:if test="$PeriodAmount != ''"> 
									<xsl:attribute name="PeriodAmount"> 
										<xsl:value-of select="$PeriodAmount"/> 
									</xsl:attribute>
								</xsl:if>
								<xsl:if test="$CoverageAmount != ''"> 
									<xsl:attribute name="CoverageAmount"> 
										<xsl:value-of select="$CoverageAmount"/> 
									</xsl:attribute>
								</xsl:if>
							</EEPaymentElement>
						</xsl:if>
					</xsl:if>
				</xsl:for-each>
				<!-- EEPaymentElement - TIME OFF -->
				<xsl:for-each select="peci:Effective_Change/peci:Time_Off_Earnings_and_Deductions[not(contains(peci:External_Payroll_Code, 'EEABS'))]">
					<xsl:sort select="../peci:Effective_Moment" order="descending"/>
					<xsl:sort select="peci:External_Payroll_Code" order="ascending"/>
					<xsl:if test="not(../following-sibling::*/peci:Time_Off_Earnings_and_Deductions/peci:External_Payroll_Code = peci:External_Payroll_Code)">
						<xsl:variable name="EffectiveDate">
							<xsl:choose>
								<xsl:when test="../peci:Effective_Moment != ''">
									<xsl:value-of select="format-date(xs:date(substring(../peci:Effective_Moment, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="''"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<xsl:variable name="Paycode">
							<xsl:if test="peci:External_Payroll_Code">
								<xsl:choose>
									<xsl:when test="contains(peci:External_Payroll_Code, ':')">
										<xsl:value-of select="substring-after(peci:External_Payroll_Code, ':')"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="peci:External_Payroll_Code"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:if>
						</xsl:variable>
						<xsl:variable name="Amount">
							<xsl:if test="peci:Grouped_Time_Off_Entry/peci:Units">
								<xsl:value-of select="peci:Grouped_Time_Off_Entry/peci:Units"/>
							</xsl:if>
						</xsl:variable>
						
						<xsl:variable name="EffectiveDateLength">
							<xsl:value-of select="10"/>
						</xsl:variable>
						<xsl:variable name="PaycodeLength">
							<xsl:value-of select="5"/>
						</xsl:variable>
						<xsl:variable name="AmountLength">
							<xsl:value-of select="100"/>
						</xsl:variable>
						
						<Errors etv:omit="true"> 
							<EffectiveDate etv:class="notReqWithWarn" etv:maxLength="{$EffectiveDateLength}" etv:targetWID="{$WorkerWID}"> 
								<xsl:value-of select="$EffectiveDate"/> 
							</EffectiveDate>
							<Paycode etv:class="notReqWithWarn" etv:maxLength="{$PaycodeLength}" etv:targetWID="{$WorkerWID}"> 
								<xsl:value-of select="$Paycode"/> 
							</Paycode>
							<Amount etv:class="notReqWithWarn" etv:maxLength="{$AmountLength}" etv:targetWID="{$WorkerWID}"> 
								<xsl:value-of select="$Amount"/> 
							</Amount>
						</Errors>
						
						<xsl:if test="1=1">
							<EEPaymentElement>
								<xsl:if test="$EffectiveDate != ''"> 
									<xsl:copy>
										<xsl:attribute name="EffectiveDate"> 
											<xsl:value-of select="$EffectiveDate"/> 
										</xsl:attribute>
									</xsl:copy>
								</xsl:if>
								<xsl:if test="$Paycode != ''"> 
									<xsl:copy>
										<xsl:attribute name="Paycode"> 
											<xsl:value-of select="$Paycode"/> 
										</xsl:attribute>
									</xsl:copy>
								</xsl:if>
								<xsl:choose>
									<xsl:when test="substring-before(peci:External_Payroll_Code, ':') = 'AnnualAmount'">
										<xsl:copy>
											<xsl:attribute name="AnnualAmount">
												<xsl:value-of select="$Amount"/>
											</xsl:attribute>
										</xsl:copy>
									</xsl:when>
									<xsl:when test="substring-before(peci:External_Payroll_Code, ':') = 'PeriodAmount'">
										<xsl:copy>	
											<xsl:attribute name="PeriodAmount">
												<xsl:value-of select="$Amount"/>
											</xsl:attribute>
										</xsl:copy>
									</xsl:when>
									<xsl:otherwise/>
								</xsl:choose>
							</EEPaymentElement>
						</xsl:if>
					</xsl:if>
				</xsl:for-each>
	
				<!-- EELocation -->
				<xsl:variable name="EffectiveDate">
					<xsl:for-each select="peci:Effective_Change[peci:Additional_Information/ptdf:Cost_Center_Effective_Date]">
						<xsl:sort select="peci:Effective_Moment" order="descending"/>
						<xsl:if test="position() = 1">
							<xsl:choose>
								<xsl:when test="
									((peci:Additional_Information/@peci:isDeleted and not(peci:Personal/@peci:isAdded) and not(peci:Additional_Information/@peci:isUpdated))
									or (peci:Additional_Information/ptdf:Cost_Center_Effective_Date/@peci:isDeleted and not(peci:Additional_Information/ptdf:Cost_Center_Effective_Date/@peci:isAdded) and not(peci:Additional_Information/ptdf:Cost_Center_Effective_Date/@peci:isUpdated)))
									or (count(peci:Additional_Information/ptdf:Cost_Center_Effective_Date) = 1
									and peci:Additional_Information/ptdf:Cost_Center_Effective_Date/@peci:priorValue != ''
									and peci:Additional_Information/ptdf:Cost_Center_Effective_Date = '')">
									<xsl:value-of select="'NULL'"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="format-date(xs:date(substring(peci:Additional_Information[not(@peci:isDeleted)]/ptdf:Cost_Center_Effective_Date[not(@peci:isDeleted)], 0, 11)), '[D01]/[M01]/[Y0001]')"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:if>
					</xsl:for-each>
				</xsl:variable>
				<xsl:variable name="Division">
					<xsl:if test="peci:Effective_Change/peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center_Hierarchy']/peci:Mapped_Value">
						<xsl:for-each select="peci:Effective_Change[peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center_Hierarchy']/peci:Mapped_Value]">
							<xsl:sort select="peci:Effective_Moment" order="descending"/>
							<xsl:if test="position() = 1">
								<xsl:choose>
									<xsl:when test="
										((peci:Position/@peci:isDeleted and not(peci:Position/@peci:isAdded) and not(peci:Position/@peci:isUpdated))
										or (peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center_Hierarchy']/@peci:isDeleted and not(peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center_Hierarchy']/@peci:isAdded) and not(peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center_Hierarchy']/@peci:isUpdated))
										or (peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center_Hierarchy']/peci:Mapped_Value/@peci:isDeleted and not(peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center_Hierarchy']/peci:Mapped_Value/@peci:isAdded) and not(peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center_Hierarchy']/peci:Mapped_Value/@peci:isUpdated)))
										or (count(peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center_Hierarchy']/peci:Mapped_Value) = 1
										and peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center_Hierarchy']/peci:Mapped_Value/@peci:priorValue != ''
										and peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center_Hierarchy']/peci:Mapped_Value = '')">
										<xsl:value-of select="'NULL'"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:choose>
											<xsl:when test="count(peci:Position[not(@peci:isDeleted)]/peci:Organization[peci:Organization_Type = 'Cost_Center_Hierarchy']/peci:Mapped_Value) > 1">
												<xsl:value-of select="peci:Position[not(@peci:isDeleted) and not(peci:Position_End_Date)]/peci:Organization[not(@peci:isDeleted)][peci:Organization_Type = 'Cost_Center_Hierarchy']/peci:Mapped_Value[not(@peci:isDeleted)]"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="peci:Position[not(@peci:isDeleted)]/peci:Organization[not(@peci:isDeleted)][peci:Organization_Type = 'Cost_Center_Hierarchy']/peci:Mapped_Value[not(@peci:isDeleted)]"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:if>
						</xsl:for-each>
					</xsl:if>
				</xsl:variable>
				<xsl:variable name="Department">
					<xsl:if test="peci:Effective_Change/peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center_Hierarchy']/peci:Mapped_Value">
						<xsl:for-each select="peci:Effective_Change[peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center_Hierarchy']/peci:Mapped_Value]">
							<xsl:sort select="peci:Effective_Moment" order="descending"/>
							<xsl:if test="position() = 1">
								<xsl:choose>
									<xsl:when test="
										((peci:Position/@peci:isDeleted and not(peci:Position/@peci:isAdded) and not(peci:Position/@peci:isUpdated))
										or (peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center_Hierarchy']/@peci:isDeleted and not(peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center_Hierarchy']/@peci:isAdded) and not(peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center_Hierarchy']/@peci:isUpdated))
										or (peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center_Hierarchy']/peci:Mapped_Value/@peci:isDeleted and not(peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center_Hierarchy']/peci:Mapped_Value/@peci:isAdded) and not(peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center_Hierarchy']/peci:Mapped_Value/@peci:isUpdated)))
										or (count(peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center_Hierarchy']/peci:Mapped_Value) = 1
										and peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center_Hierarchy']/peci:Mapped_Value/@peci:priorValue != ''
										and peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center_Hierarchy']/peci:Mapped_Value = '')">
										<xsl:value-of select="'NULL'"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:choose>
											<xsl:when test="count(peci:Position[not(@peci:isDeleted)]/peci:Organization[peci:Organization_Type = 'Cost_Center_Hierarchy']/peci:Mapped_Value) > 1">
												<xsl:value-of select="peci:Position[not(@peci:isDeleted) and not(peci:Position_End_Date)]/peci:Organization[not(@peci:isDeleted)][peci:Organization_Type = 'Cost_Center_Hierarchy']/peci:Mapped_Value[not(@peci:isDeleted)]"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="peci:Position[not(@peci:isDeleted)]/peci:Organization[not(@peci:isDeleted)][peci:Organization_Type = 'Cost_Center_Hierarchy']/peci:Mapped_Value[not(@peci:isDeleted)]"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:if>
						</xsl:for-each>
					</xsl:if>
				</xsl:variable>
				<xsl:variable name="CostCentre1">
					<xsl:if test="peci:Effective_Change/peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center']/peci:Mapped_Value">
						<xsl:for-each select="peci:Effective_Change[peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center']/peci:Mapped_Value]">
							<xsl:sort select="peci:Effective_Moment" order="descending"/>
							<xsl:if test="position() = 1">
								<xsl:choose>
									<xsl:when test="
										((peci:Position/@peci:isDeleted and not(peci:Position/@peci:isAdded) and not(peci:Position/@peci:isUpdated))
										or (peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center']/@peci:isDeleted and not(peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center']/@peci:isAdded) and not(peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center']/@peci:isUpdated))
										or (peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center']/peci:Mapped_Value/@peci:isDeleted and not(peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center']/peci:Mapped_Value/@peci:isAdded) and not(peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center']/peci:Mapped_Value/@peci:isUpdated)))
										or (count(peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center']/peci:Mapped_Value) = 1
										and peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center']/peci:Mapped_Value/@peci:priorValue != ''
										and peci:Position/peci:Organization[peci:Organization_Type = 'Cost_Center']/peci:Mapped_Value = '')">
										<xsl:value-of select="'NULL'"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:choose>
											<xsl:when test="count(peci:Position[not(@peci:isDeleted)]/peci:Organization[not(@peci:isDeleted)][peci:Organization_Type = 'Cost_Center']/peci:Mapped_Value[not(@peci:isDeleted)]) > 1">
												<xsl:value-of select="peci:Position[not(@peci:isDeleted) and not(peci:Position_End_Date)]/peci:Organization[not(@peci:isDeleted)][peci:Organization_Type = 'Cost_Center']/peci:Mapped_Value[not(@peci:isDeleted)]"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="peci:Position[not(@peci:isDeleted)]/peci:Organization[not(@peci:isDeleted)][peci:Organization_Type = 'Cost_Center']/peci:Mapped_Value[not(@peci:isDeleted)]"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:if>
						</xsl:for-each>
					</xsl:if>
				</xsl:variable>
				
				<xsl:variable name="EffectiveDateLength">
					<xsl:value-of select="10"/>
				</xsl:variable>
				<xsl:variable name="DivisionLength">
					<xsl:value-of select="5"/>
				</xsl:variable>
				<xsl:variable name="DepartmentLength">
					<xsl:value-of select="5"/>
				</xsl:variable>
				<xsl:variable name="CostCentre1Length">
					<xsl:value-of select="12"/>
				</xsl:variable>
				
				<Errors etv:omit="true">
					<EffectiveDate etv:class="notReqWithWarn" etv:maxLength="{$EffectiveDateLength}" etv:targetWID="{$WorkerWID}">
						<xsl:value-of select="$EffectiveDate"/>
					</EffectiveDate>
					<Division etv:class="notReqWithWarn" etv:maxLength="{$DivisionLength}" etv:targetWID="{$WorkerWID}">
						<xsl:value-of select="$Division"/>
					</Division>
					<Department etv:class="notReqWithWarn" etv:maxLength="{$DepartmentLength}" etv:targetWID="{$WorkerWID}">
						<xsl:value-of select="$Department"/>
					</Department>
					<CostCentre1 etv:class="notReqWithWarn" etv:maxLength="{$CostCentre1Length}" etv:targetWID="{$WorkerWID}">
						<xsl:value-of select="$CostCentre1"/>
					</CostCentre1>
				</Errors>
	
				<xsl:if test="1=1">
					<EELocation>
						<xsl:if test="$EffectiveDate != ''">
							<xsl:attribute name="EffectiveDate">
								<xsl:value-of select="$EffectiveDate"/>
							</xsl:attribute>
						</xsl:if>
						<xsl:if test="$Division != ''">
							<xsl:attribute name="Division">
								<xsl:value-of select="$Division"/>
							</xsl:attribute>
						</xsl:if>
						<xsl:if test="$Department != ''">
							<xsl:attribute name="Department">
								<xsl:value-of select="$Department"/>
							</xsl:attribute>
						</xsl:if>
						<xsl:if test="$CostCentre1 != ''">
							<xsl:attribute name="CostCentre1">
								<xsl:value-of select="$CostCentre1"/>
							</xsl:attribute>
						</xsl:if>
					</EELocation>
				</xsl:if>
	
				<!-- Variable usesd for Adopion Leave -->
				<xsl:variable name="gender">
					<xsl:for-each select="peci:Effective_Change[peci:Personal/peci:Gender]">
						<xsl:sort select="peci:Effective_Moment" order="descending"/>
						<xsl:if test="position() = 1">
							<xsl:choose>
								<xsl:when test="
										((peci:Personal/@peci:isDeleted and not(peci:Personal/@peci:isAdded) and not(peci:Personal/@peci:isUpdated))
										or (peci:Personal/peci:Gender/@peci:isDeleted and not(peci:Personal/peci:Gender/@peci:isAdded) and not(peci:Personal/peci:Gender/@peci:isUpdated)))
										or (count(peci:Personal/peci:Gender) = 1
										and peci:Personal/peci:Gender/@peci:priorValue != ''
										and peci:Personal/peci:Gender = '')">
									<xsl:value-of select="'NULL'"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="peci:Personal[not(@peci:isDeleted)]/peci:Gender[not(@peci:isDeleted)]"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:if>
					</xsl:for-each>
				</xsl:variable>
				<!-- EESAPPeriodDetail -->
				<xsl:if test="$gender = 'F'">
					<xsl:for-each select="peci:Effective_Change/peci:Leave_of_Absence[substring-before(peci:Leave_of_Absence_Type, '_') = 'ADOPTION']">
						<xsl:sort select="../peci:Effective_Moment" order="descending"/>
						<xsl:if test="
								not(../following-sibling::*/peci:Leave_of_Absence/peci:Leave_of_Absence_Type = peci:Leave_of_Absence_Type)
								and not(../following-sibling::*/peci:Leave_of_Absence/peci:Leave_Start_Date = peci:Leave_Start_Date)">
							<xsl:variable name="MatchNotificationDate">
								<xsl:if test="peci:Adoption_Notification_Date">
									<xsl:value-of select="format-date(xs:date(substring(peci:Adoption_Notification_Date, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
								</xsl:if>
							</xsl:variable>
							<xsl:variable name="LeaveStartDate">
								<xsl:if test="peci:Leave_Start_Date">
									<xsl:value-of select="format-date(xs:date(substring(peci:Leave_Start_Date, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
								</xsl:if>
							</xsl:variable>
							<xsl:variable name="AbsenceType">
								<xsl:value-of select="'MAT'"/>
							</xsl:variable>
							<xsl:variable name="OFPSchemeNo">
								<xsl:if test="peci:Leave_of_Absence_Type">
									<xsl:value-of select="substring-after(peci:Leave_of_Absence_Type, '_')"/>
								</xsl:if>
							</xsl:variable>
							<xsl:variable name="ExpectedPlacementDate">
								<xsl:if test="peci:Adoption_Placement_Date">
									<xsl:value-of select="format-date(xs:date(substring(peci:Adoption_Placement_Date, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
								</xsl:if>
							</xsl:variable>
							<xsl:variable name="ReturnToWorkDate">
								<xsl:if test="peci:Leave_End_Date">
									<xsl:value-of select="format-date(xs:date(substring(peci:Leave_End_Date, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
								</xsl:if>
							</xsl:variable>
							
							<xsl:variable name="MatchNotificationDateLength">
								<xsl:value-of select="10"/>
							</xsl:variable>
							<xsl:variable name="LeaveStartDateLength">
								<xsl:value-of select="10"/>
							</xsl:variable>
							<xsl:variable name="AbsenceTypeLength">
								<xsl:value-of select="5"/>
							</xsl:variable>
							<xsl:variable name="OFPSchemeNoLength">
								<xsl:value-of select="7"/>
							</xsl:variable>
							<xsl:variable name="ExpectedPlacementDateLength">
								<xsl:value-of select="10"/>
							</xsl:variable>
							<xsl:variable name="ReturnToWorkDateLength">
								<xsl:value-of select="10"/>
							</xsl:variable>
							
							<Errors etv:omit="true">
								<MatchNotificationDate etv:class="notReqWithWarn" etv:maxLength="{$MatchNotificationDateLength}" etv:targetWID="{$WorkerWID}">
									<xsl:value-of select="$MatchNotificationDate"/>
								</MatchNotificationDate>
								<LeaveStartDate etv:class="notReqWithWarn" etv:maxLength="{$LeaveStartDateLength}" etv:targetWID="{$WorkerWID}">
									<xsl:value-of select="$LeaveStartDate"/>
								</LeaveStartDate>
								<AbsenceType etv:class="notReqWithWarn" etv:maxLength="{$AbsenceTypeLength}" etv:targetWID="{$WorkerWID}">
									<xsl:value-of select="$AbsenceType"/>
								</AbsenceType>
								<OFPSchemeNo etv:class="notReqWithWarn" etv:maxLength="{$OFPSchemeNoLength}" etv:targetWID="{$WorkerWID}">
									<xsl:value-of select="$OFPSchemeNo"/>
								</OFPSchemeNo>
								<ExpectedPlacementDate etv:class="notReqWithWarn" etv:maxLength="{$ExpectedPlacementDateLength}" etv:targetWID="{$WorkerWID}">
									<xsl:value-of select="$ExpectedPlacementDate"/>
								</ExpectedPlacementDate>
								<ReturnToWorkDate etv:class="notReqWithWarn" etv:maxLength="{$ReturnToWorkDateLength}" etv:targetWID="{$WorkerWID}">
									<xsl:value-of select="$ReturnToWorkDate"/>
								</ReturnToWorkDate>
							</Errors>
							
							<xsl:if test="1=1">
								<EESAPPeriodDetail>
									<xsl:if test="$MatchNotificationDate != ''">
										<xsl:attribute name="MatchNotificationDate">
											<xsl:value-of select="$MatchNotificationDate"/>
										</xsl:attribute>
									</xsl:if>
									<xsl:if test="$LeaveStartDate != ''">
										<xsl:attribute name="LeaveStartDate">
											<xsl:value-of select="$LeaveStartDate"/>
										</xsl:attribute>
									</xsl:if>
									<xsl:if test="$AbsenceType != ''">
										<xsl:attribute name="AbsenceType">
											<xsl:value-of select="$AbsenceType"/>
										</xsl:attribute>
									</xsl:if>
									<xsl:if test="$OFPSchemeNo != ''">
										<xsl:attribute name="OFPSchemeNo">
											<xsl:value-of select="$OFPSchemeNo"/>
										</xsl:attribute>
									</xsl:if>
									<xsl:if test="$ExpectedPlacementDate != ''">
										<xsl:attribute name="ExpectedPlacementDate">
											<xsl:value-of select="$ExpectedPlacementDate"/>
										</xsl:attribute>
									</xsl:if>
									<xsl:if test="$ReturnToWorkDate != ''">
										<xsl:attribute name="ReturnToWorkDate">
											<xsl:value-of select="$ReturnToWorkDate"/>
										</xsl:attribute>
									</xsl:if>
								</EESAPPeriodDetail>
							</xsl:if>
						</xsl:if>
					</xsl:for-each>
				</xsl:if>
				<!-- EESMPPeriodDetail -->
				<xsl:for-each select="peci:Effective_Change/peci:Leave_of_Absence[substring-before(peci:Leave_of_Absence_Type, '_') = 'MATERNITY']">
					<xsl:sort select="../peci:Effective_Moment" order="descending"/>
					<xsl:if test="
							not(../following-sibling::*/peci:Leave_of_Absence/peci:Leave_of_Absence_Type = peci:Leave_of_Absence_Type)
							and not(../following-sibling::*/peci:Leave_of_Absence/peci:Leave_Start_Date = peci:Leave_Start_Date)">
						<xsl:variable name="BabyDueDate">
							<xsl:if test="peci:Expected_Due_Date">
								<xsl:value-of select="format-date(xs:date(substring(peci:Expected_Due_Date, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
							</xsl:if>
						</xsl:variable>
						<xsl:variable name="LeaveStartDate">
							<xsl:if test="peci:Leave_Start_Date">
								<xsl:value-of select="format-date(xs:date(substring(peci:Leave_Start_Date, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
							</xsl:if>
						</xsl:variable>
						<xsl:variable name="AbsenceType">
							<xsl:value-of select="'MAT'"/>
						</xsl:variable>
						<xsl:variable name="OFPSchemeNo">
							<xsl:if test="peci:Leave_of_Absence_Type">
								<xsl:value-of select="substring-after(peci:Leave_of_Absence_Type, '_')"/>
							</xsl:if>
						</xsl:variable>
						<xsl:variable name="ReturnToWorkDate">
							<xsl:if test="peci:Leave_End_Date">
								<xsl:choose>
									<xsl:when test="peci:Leave_End_Date != ''">
										<xsl:value-of select="format-date(xs:date(substring(peci:Leave_End_Date, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="''"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:if>
						</xsl:variable>
						
						<xsl:variable name="BabyDueDateLength">
							<xsl:value-of select="10"/>
						</xsl:variable>
						<xsl:variable name="LeaveStartDateLength">
							<xsl:value-of select="10"/>
						</xsl:variable>
						<xsl:variable name="AbsenceTypeLength">
							<xsl:value-of select="5"/>
						</xsl:variable>
						<xsl:variable name="OFPSchemeNoLength">
							<xsl:value-of select="7"/>
						</xsl:variable>
						<xsl:variable name="ReturnToWorkDateLength">
							<xsl:value-of select="10"/>
						</xsl:variable>
						
						<Errors etv:omit="true">
							<BabyDueDate etv:class="notReqWithWarn" etv:maxLength="{$BabyDueDateLength}" etv:targetWID="{$WorkerWID}">
								<xsl:value-of select="$BabyDueDate"/>
							</BabyDueDate>
							<LeaveStartDate etv:class="notReqWithWarn" etv:maxLength="{$LeaveStartDateLength}" etv:targetWID="{$WorkerWID}">
								<xsl:value-of select="$LeaveStartDate"/>
							</LeaveStartDate>
							<AbsenceType etv:class="notReqWithWarn" etv:maxLength="{$AbsenceTypeLength}" etv:targetWID="{$WorkerWID}">
								<xsl:value-of select="$AbsenceType"/>
							</AbsenceType>
							<OFPSchemeNo etv:class="notReqWithWarn" etv:maxLength="{$OFPSchemeNoLength}" etv:targetWID="{$WorkerWID}">
								<xsl:value-of select="$OFPSchemeNo"/>
							</OFPSchemeNo>
							<ReturnToWorkDate etv:class="notReqWithWarn" etv:maxLength="{$ReturnToWorkDateLength}" etv:targetWID="{$WorkerWID}">
								<xsl:value-of select="$ReturnToWorkDate"/>
							</ReturnToWorkDate>
						</Errors>
						
						<xsl:if test="1=1">
							<EESMPPeriodDetail>
								<xsl:if test="$BabyDueDate != ''">
									<xsl:attribute name="BabyDueDate">
										<xsl:value-of select="$BabyDueDate"/>
									</xsl:attribute>
								</xsl:if>
								<xsl:if test="$LeaveStartDate != ''">
									<xsl:attribute name="LeaveStartDate">
										<xsl:value-of select="$LeaveStartDate"/>
									</xsl:attribute>
								</xsl:if>
								<xsl:if test="$AbsenceType != ''">
									<xsl:attribute name="AbsenceType">
										<xsl:value-of select="$AbsenceType"/>
									</xsl:attribute>
								</xsl:if>
								<xsl:if test="$OFPSchemeNo != ''">
									<xsl:attribute name="OFPSchemeNo">
										<xsl:value-of select="$OFPSchemeNo"/>
									</xsl:attribute>
								</xsl:if>
								<xsl:if test="$ReturnToWorkDate != ''">
									<xsl:attribute name="ReturnToWorkDate">
										<xsl:value-of select="$ReturnToWorkDate"/>
									</xsl:attribute>
								</xsl:if>
							</EESMPPeriodDetail>
						</xsl:if>
					</xsl:if>
				</xsl:for-each>
				<!-- EESPPAPeriodDetail -->
				<xsl:if test="$gender = 'M'">
					<xsl:for-each select="peci:Effective_Change/peci:Leave_of_Absence[substring-before(peci:Leave_of_Absence_Type, '_') = 'ADOPTION']">
						<xsl:sort select="../peci:Effective_Moment" order="descending"/>
						<xsl:if test="
							not(../following-sibling::*/peci:Leave_of_Absence/peci:Leave_of_Absence_Type = peci:Leave_of_Absence_Type)
							and not(../following-sibling::*/peci:Leave_of_Absence/peci:Leave_Start_Date = peci:Leave_Start_Date)">
							<xsl:variable name="MatchNotificationDate">
								<xsl:if test="peci:Adoption_Notification_Date">
									<xsl:value-of select="format-date(xs:date(substring(peci:Adoption_Notification_Date, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
								</xsl:if>
							</xsl:variable>
							<xsl:variable name="LeaveStartDate">
								<xsl:if test="peci:Leave_Start_Date">
									<xsl:value-of select="format-date(xs:date(substring(peci:Leave_Start_Date, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
								</xsl:if>
							</xsl:variable>
							<xsl:variable name="AbsenceType">
								<xsl:value-of select="'PAT'"/>
							</xsl:variable>
							<xsl:variable name="OFPSchemeNo">
								<xsl:if test="peci:Leave_of_Absence_Type">
									<xsl:value-of select="substring-after(peci:Leave_of_Absence_Type, '_')"/>
								</xsl:if>
							</xsl:variable>
							<xsl:variable name="ExpectedPlacementDate">
								<xsl:if test="peci:Adoption_Placement_Date">
									<xsl:value-of select="format-date(xs:date(substring(peci:Adoption_Placement_Date, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
								</xsl:if>
							</xsl:variable>
							<xsl:variable name="ReturnToWorkDate">
								<xsl:if test="peci:Leave_End_Date">
									<xsl:value-of select="format-date(xs:date(substring(peci:Leave_End_Date, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
								</xsl:if>
							</xsl:variable>
							
							<xsl:variable name="MatchNotificationDateLength">
								<xsl:value-of select="10"/>
							</xsl:variable>
							<xsl:variable name="LeaveStartDateLength">
								<xsl:value-of select="10"/>
							</xsl:variable>
							<xsl:variable name="AbsenceTypeLength">
								<xsl:value-of select="5"/>
							</xsl:variable>
							<xsl:variable name="OFPSchemeNoLength">
								<xsl:value-of select="7"/>
							</xsl:variable>
							<xsl:variable name="ExpectedPlacementDateLength">
								<xsl:value-of select="10"/>
							</xsl:variable>
							<xsl:variable name="ReturnToWorkDateLength">
								<xsl:value-of select="10"/>
							</xsl:variable>
							
							<Errors etv:omit="true">
								<MatchNotificationDate etv:class="notReqWithWarn" etv:maxLength="{$MatchNotificationDateLength}" etv:targetWID="{$WorkerWID}">
									<xsl:value-of select="$MatchNotificationDate"/>
								</MatchNotificationDate>
								<LeaveStartDate etv:class="notReqWithWarn" etv:maxLength="{$LeaveStartDateLength}" etv:targetWID="{$WorkerWID}">
									<xsl:value-of select="$LeaveStartDate"/>
								</LeaveStartDate>
								<AbsenceType etv:class="notReqWithWarn" etv:maxLength="{$AbsenceTypeLength}" etv:targetWID="{$WorkerWID}">
									<xsl:value-of select="$AbsenceType"/>
								</AbsenceType>
								<OFPSchemeNo etv:class="notReqWithWarn" etv:maxLength="{$OFPSchemeNoLength}" etv:targetWID="{$WorkerWID}">
									<xsl:value-of select="$OFPSchemeNo"/>
								</OFPSchemeNo>
								<ExpectedPlacementDate etv:class="notReqWithWarn" etv:maxLength="{$ExpectedPlacementDateLength}" etv:targetWID="{$WorkerWID}">
									<xsl:value-of select="$ExpectedPlacementDate"/>
								</ExpectedPlacementDate>
								<ReturnToWorkDate etv:class="notReqWithWarn" etv:maxLength="{$ReturnToWorkDateLength}" etv:targetWID="{$WorkerWID}">
									<xsl:value-of select="$ReturnToWorkDate"/>
								</ReturnToWorkDate>
							</Errors>
							
							<xsl:if test="1=1">
								<EESPPAPeriodDetail>
									<xsl:if test="$MatchNotificationDate != ''">
										<xsl:attribute name="MatchNotificationDate">
											<xsl:value-of select="$MatchNotificationDate"/>
										</xsl:attribute>
									</xsl:if>
									<xsl:if test="$LeaveStartDate != ''">
										<xsl:attribute name="LeaveStartDate">
											<xsl:value-of select="$LeaveStartDate"/>
										</xsl:attribute>
									</xsl:if>
									<xsl:if test="$AbsenceType != ''">
										<xsl:attribute name="AbsenceType">
											<xsl:value-of select="$AbsenceType"/>
										</xsl:attribute>
									</xsl:if>
									<xsl:if test="$OFPSchemeNo != ''">
										<xsl:attribute name="OFPSchemeNo">
											<xsl:value-of select="$OFPSchemeNo"/>
										</xsl:attribute>
									</xsl:if>
									<xsl:if test="$ExpectedPlacementDate != ''">
										<xsl:attribute name="ExpectedPlacementDate">
											<xsl:value-of select="$ExpectedPlacementDate"/>
										</xsl:attribute>
									</xsl:if>
									<xsl:if test="$ReturnToWorkDate != ''">
										<xsl:attribute name="ReturnToWorkDate">
											<xsl:value-of select="$ReturnToWorkDate"/>
										</xsl:attribute>
									</xsl:if>
								</EESPPAPeriodDetail>
							</xsl:if>
						</xsl:if>
					</xsl:for-each>
				</xsl:if>
				<!-- EESPPBPeriodDetail -->
				<xsl:for-each select="peci:Effective_Change/peci:Leave_of_Absence[substring-before(peci:Leave_of_Absence_Type, '_') = 'PATERNITY']">
					<xsl:sort select="../peci:Effective_Moment" order="descending"/>
					<xsl:if test="
							not(../following-sibling::*/peci:Leave_of_Absence/peci:Leave_of_Absence_Type = peci:Leave_of_Absence_Type)
							and not(../following-sibling::*/peci:Leave_of_Absence/peci:Leave_Start_Date = peci:Leave_Start_Date)">
						<xsl:variable name="BabyDueDate">
							<xsl:if test="peci:Expected_Due_Date">
								<xsl:value-of select="format-date(xs:date(substring(peci:Expected_Due_Date, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
							</xsl:if>
						</xsl:variable>
						<xsl:variable name="LeaveStartDate">
							<xsl:if test="peci:Leave_Start_Date">
								<xsl:value-of select="format-date(xs:date(substring(peci:Leave_Start_Date, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
							</xsl:if>
						</xsl:variable>
						<xsl:variable name="AbsenceType">
							<xsl:value-of select="'PAT'"/>
						</xsl:variable>
						<xsl:variable name="OFPSchemeNo">
							<xsl:if test="peci:Leave_of_Absence_Type">
								<xsl:value-of select="substring-after(peci:Leave_of_Absence_Type, '_')"/>
							</xsl:if>
						</xsl:variable>
						<xsl:variable name="ReturnToWorkDate">
							<xsl:if test="peci:Leave_End_Date">
								<xsl:choose>
									<xsl:when test="peci:Leave_End_Date != ''">
										<xsl:value-of select="format-date(xs:date(substring(peci:Leave_End_Date, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="''"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:if>
						</xsl:variable>
						
						<xsl:variable name="BabyDueDateLength">
							<xsl:value-of select="10"/>
						</xsl:variable>
						<xsl:variable name="LeaveStartDateLength">
							<xsl:value-of select="10"/>
						</xsl:variable>
						<xsl:variable name="AbsenceTypeLength">
							<xsl:value-of select="5"/>
						</xsl:variable>
						<xsl:variable name="OFPSchemeNoLength">
							<xsl:value-of select="7"/>
						</xsl:variable>
						<xsl:variable name="ReturnToWorkDateLength">
							<xsl:value-of select="10"/>
						</xsl:variable>
						
						<Errors etv:omit="true">
							<BabyDueDate etv:class="notReqWithWarn" etv:maxLength="{$BabyDueDateLength}" etv:targetWID="{$WorkerWID}">
								<xsl:value-of select="$BabyDueDate"/>
							</BabyDueDate>
							<LeaveStartDate etv:class="notReqWithWarn" etv:maxLength="{$LeaveStartDateLength}" etv:targetWID="{$WorkerWID}">
								<xsl:value-of select="$LeaveStartDate"/>
							</LeaveStartDate>
							<AbsenceType etv:class="notReqWithWarn" etv:maxLength="{$AbsenceTypeLength}" etv:targetWID="{$WorkerWID}">
								<xsl:value-of select="$AbsenceType"/>
							</AbsenceType>
							<OFPSchemeNo etv:class="notReqWithWarn" etv:maxLength="{$OFPSchemeNoLength}" etv:targetWID="{$WorkerWID}">
								<xsl:value-of select="$OFPSchemeNo"/>
							</OFPSchemeNo>
							<ReturnToWorkDate etv:class="notReqWithWarn" etv:maxLength="{$ReturnToWorkDateLength}" etv:targetWID="{$WorkerWID}">
								<xsl:value-of select="$ReturnToWorkDate"/>
							</ReturnToWorkDate>
						</Errors>
						
						<xsl:if test="1=1">
							<EESPPBPeriodDetail>
								<xsl:if test="$BabyDueDate != ''">
									<xsl:attribute name="BabyDueDate">
										<xsl:value-of select="$BabyDueDate"/>
									</xsl:attribute>
								</xsl:if>
								<xsl:if test="$LeaveStartDate != ''">
									<xsl:attribute name="LeaveStartDate">
										<xsl:value-of select="$LeaveStartDate"/>
									</xsl:attribute>
								</xsl:if>
								<xsl:if test="$AbsenceType != ''">
									<xsl:attribute name="AbsenceType">
										<xsl:value-of select="$AbsenceType"/>
									</xsl:attribute>
								</xsl:if>
								<xsl:if test="$OFPSchemeNo != ''">
									<xsl:attribute name="OFPSchemeNo">
										<xsl:value-of select="$OFPSchemeNo"/>
									</xsl:attribute>
								</xsl:if>
								<xsl:if test="$ReturnToWorkDate != ''">
									<xsl:attribute name="ReturnToWorkDate">
										<xsl:value-of select="$ReturnToWorkDate"/>
									</xsl:attribute>
								</xsl:if>
							</EESPPBPeriodDetail>
						</xsl:if>
					</xsl:if>
				</xsl:for-each>
				<!-- EEASPPAPeriodDetail -->
				<xsl:if test="$gender = 'M'">
					<xsl:for-each select="peci:Effective_Change/peci:Leave_of_Absence[substring-before(peci:Leave_of_Absence_Type, '_') = 'ADOPTION']">
						<xsl:sort select="../peci:Effective_Moment" order="descending"/>
						<xsl:if test="
								not(../following-sibling::*/peci:Leave_of_Absence/peci:Leave_of_Absence_Type = peci:Leave_of_Absence_Type)
								and not(../following-sibling::*/peci:Leave_of_Absence/peci:Leave_Start_Date = peci:Leave_Start_Date)">
	
							<xsl:variable name="MatchNotificationDate">
								<xsl:if test="peci:Adoption_Notification_Date">
									<xsl:value-of select="format-date(xs:date(substring(peci:Adoption_Notification_Date, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
								</xsl:if>
							</xsl:variable>
							<xsl:variable name="LeaveStartDate">
								<xsl:if test="peci:Leave_Start_Date">
									<xsl:value-of select="format-date(xs:date(substring(peci:Leave_Start_Date, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
								</xsl:if>
							</xsl:variable>
							<xsl:variable name="AbsenceType">
								<xsl:value-of select="'PAT'"/>
							</xsl:variable>
							<xsl:variable name="OFPSchemeNo">
								<xsl:if test="peci:Leave_of_Absence_Type">
									<xsl:value-of select="substring-after(peci:Leave_of_Absence_Type, '_')"/>
								</xsl:if>
							</xsl:variable>
							<xsl:variable name="ExpectedPlacementDate">
								<xsl:if test="peci:Adoption_Placement_Date">
									<xsl:value-of select="format-date(xs:date(substring(peci:Adoption_Placement_Date, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
								</xsl:if>
							</xsl:variable>
							<xsl:variable name="StartDateSAPPayments">
								<xsl:if test="peci:Leave_Start_Date">
									<xsl:value-of select="xs:date(substring(peci:Leave_Start_Date, 0, 11))"/>
								</xsl:if>
							</xsl:variable>
							<xsl:variable name="EndDateSAPPayments">
								<xsl:if test="peci:Leave_End_Date">
									<xsl:value-of select="format-date(xs:date(substring(peci:Leave_End_Date, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
								</xsl:if>
							</xsl:variable>
							<xsl:variable name="ReturnToWorkDate">
								<xsl:if test="peci:Leave_End_Date">
									<xsl:value-of select="format-date(xs:date(substring(peci:Leave_End_Date, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
								</xsl:if>
							</xsl:variable>
							
							<xsl:variable name="MatchNotificationDateLength">
								<xsl:value-of select="10"/>
							</xsl:variable>
							<xsl:variable name="LeaveStartDateLength">
								<xsl:value-of select="10"/>
							</xsl:variable>
							<xsl:variable name="AbsenceTypeLength">
								<xsl:value-of select="5"/>
							</xsl:variable>
							<xsl:variable name="OFPSchemeNoLength">
								<xsl:value-of select="7"/>
							</xsl:variable>
							<xsl:variable name="ExpectedPlacementDateLength">
								<xsl:value-of select="10"/>
							</xsl:variable>
							<xsl:variable name="StartDateSAPPaymentsLength">
								<xsl:value-of select="10"/>
							</xsl:variable>
							<xsl:variable name="EndDateSAPPaymentsLength">
								<xsl:value-of select="10"/>
							</xsl:variable>
							<xsl:variable name="ReturnToWorkDateLength">
								<xsl:value-of select="10"/>
							</xsl:variable>
							
							<Errors etv:omit="true">
								<MatchNotificationDate etv:class="notReqWithWarn" etv:maxLength="{$MatchNotificationDateLength}" etv:targetWID="{$WorkerWID}">
									<xsl:value-of select="$MatchNotificationDate"/>
								</MatchNotificationDate>
								<LeaveStartDate etv:class="notReqWithWarn" etv:maxLength="{$LeaveStartDateLength}" etv:targetWID="{$WorkerWID}">
									<xsl:value-of select="$LeaveStartDate"/>
								</LeaveStartDate>
								<AbsenceType etv:class="notReqWithWarn" etv:maxLength="{$AbsenceTypeLength}" etv:targetWID="{$WorkerWID}">
									<xsl:value-of select="$AbsenceType"/>
								</AbsenceType>
								<OFPSchemeNo etv:class="notReqWithWarn" etv:maxLength="{$OFPSchemeNoLength}" etv:targetWID="{$WorkerWID}">
									<xsl:value-of select="$OFPSchemeNo"/>
								</OFPSchemeNo>
								<ExpectedPlacementDate etv:class="notReqWithWarn" etv:maxLength="{$ExpectedPlacementDateLength}" etv:targetWID="{$WorkerWID}">
									<xsl:value-of select="$ExpectedPlacementDate"/>
								</ExpectedPlacementDate>
								<StartDateSAPPayments etv:class="notReqWithWarn" etv:maxLength="{$StartDateSAPPaymentsLength}" etv:targetWID="{$WorkerWID}">
									<xsl:value-of select="$StartDateSAPPayments"/>
								</StartDateSAPPayments>
								<EndDateSAPPayments etv:class="notReqWithWarn" etv:maxLength="{$EndDateSAPPaymentsLength}" etv:targetWID="{$WorkerWID}">
									<xsl:value-of select="$EndDateSAPPayments"/>
								</EndDateSAPPayments>
								<ReturnToWorkDate etv:class="notReqWithWarn" etv:maxLength="{$ReturnToWorkDateLength}" etv:targetWID="{$WorkerWID}">
									<xsl:value-of select="$ReturnToWorkDate"/>
								</ReturnToWorkDate>
							</Errors>
							
							<xsl:if test="1=1">
								<EEASPPAPeriodDetail>
									<xsl:if test="$MatchNotificationDate != ''">
										<xsl:attribute name="MatchNotificationDate">
											<xsl:value-of select="$MatchNotificationDate"/>
										</xsl:attribute>
									</xsl:if>
									<xsl:if test="$LeaveStartDate != ''">
										<xsl:attribute name="LeaveStartDate">
											<xsl:value-of select="$LeaveStartDate"/>
										</xsl:attribute>
									</xsl:if>
									<xsl:if test="$AbsenceType != ''">
										<xsl:attribute name="AbsenceType">
											<xsl:value-of select="$AbsenceType"/>
										</xsl:attribute>
									</xsl:if>
									<xsl:if test="$OFPSchemeNo != ''">
										<xsl:attribute name="OFPSchemeNo">
											<xsl:value-of select="$OFPSchemeNo"/>
										</xsl:attribute>
									</xsl:if>
									<xsl:if test="$ExpectedPlacementDate != ''">
										<xsl:attribute name="ExpectedPlacementDate">
											<xsl:value-of select="$ExpectedPlacementDate"/>
										</xsl:attribute>
									</xsl:if>
									<xsl:if test="$StartDateSAPPayments != ''">
										<xsl:attribute name="ExpectedPlacementDate">
											<xsl:value-of select="$ExpectedPlacementDate"/>
										</xsl:attribute>
									</xsl:if>
									<xsl:if test="$EndDateSAPPayments != ''">
										<xsl:attribute name="ExpectedPlacementDate">
											<xsl:value-of select="$ExpectedPlacementDate"/>
										</xsl:attribute>
									</xsl:if>
									<xsl:if test="$ReturnToWorkDate != ''">
										<xsl:attribute name="ReturnToWorkDate">
											<xsl:value-of select="$ReturnToWorkDate"/>
										</xsl:attribute>
									</xsl:if>
								</EEASPPAPeriodDetail>
							</xsl:if>
						</xsl:if>
					</xsl:for-each>
				</xsl:if>
				<!-- EEASPPBPeriodDetail -->
				<xsl:for-each select="peci:Effective_Change/peci:Leave_of_Absence[substring-before(peci:Leave_of_Absence_Type, '_') = 'PATERNITY']">
					<xsl:sort select="../peci:Effective_Moment" order="descending"/>
					<xsl:if test="
							not(../following-sibling::*/peci:Leave_of_Absence/peci:Leave_of_Absence_Type = peci:Leave_of_Absence_Type)
							and not(../following-sibling::*/peci:Leave_of_Absence/peci:Leave_Start_Date = peci:Leave_Start_Date)">
						<xsl:variable name="BabyDueDate">
							<xsl:if test="peci:Expected_Due_Date">
								<xsl:value-of select="format-date(xs:date(substring(peci:Expected_Due_Date, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
							</xsl:if>
						</xsl:variable>
						<xsl:variable name="LeaveStartDate">
							<xsl:if test="peci:Leave_Start_Date">
								<xsl:value-of select="format-date(xs:date(substring(peci:Leave_Start_Date, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
							</xsl:if>
						</xsl:variable>
						<xsl:variable name="AbsenceType">
							<xsl:value-of select="'PAT'"/>
						</xsl:variable>
						<xsl:variable name="OFPSchemeNo">
							<xsl:if test="peci:Leave_of_Absence_Type">
								<xsl:value-of select="substring-after(peci:Leave_of_Absence_Type, '_')"/>
							</xsl:if>
						</xsl:variable>
						<xsl:variable name="StartDateSMPPayments">
							<xsl:if test="peci:Leave_Start_Date">
								<xsl:value-of select="format-date(xs:date(substring(peci:Leave_Start_Date, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
							</xsl:if>
						</xsl:variable>
						<xsl:variable name="EndDateSMPPayments">
							<xsl:if test="peci:Leave_End_Date">
								<xsl:choose>
									<xsl:when test="peci:Leave_End_Date != ''">
										<xsl:value-of select="format-date(xs:date(substring(peci:Leave_End_Date, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="''"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:if>
						</xsl:variable>
						<xsl:variable name="ReturnToWorkDate">
							<xsl:if test="peci:Leave_End_Date">
								<xsl:choose>
									<xsl:when test="peci:Leave_End_Date != ''">
										<xsl:value-of select="format-date(xs:date(substring(peci:Leave_End_Date, 0, 11)), '[D01]/[M01]/[Y0001]')"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="''"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:if>
						</xsl:variable>
						
						<xsl:variable name="BabyDueDateLength">
							<xsl:value-of select="10"/>
						</xsl:variable>
						<xsl:variable name="LeaveStartDateLength">
							<xsl:value-of select="10"/>
						</xsl:variable>
						<xsl:variable name="AbsenceTypeLength">
							<xsl:value-of select="5"/>
						</xsl:variable>
						<xsl:variable name="OFPSchemeNoLength">
							<xsl:value-of select="7"/>
						</xsl:variable>
						<xsl:variable name="StartDateSMPPaymentsLength">
							<xsl:value-of select="10"/>
						</xsl:variable>
						<xsl:variable name="EndDateSMPPaymentsLength">
							<xsl:value-of select="10"/>
						</xsl:variable>
						<xsl:variable name="ReturnToWorkDateLength">
							<xsl:value-of select="10"/>
						</xsl:variable>
						
						<Errors etv:omit="true">
							<BabyDueDate etv:class="notReqWithWarn" etv:maxLength="{$BabyDueDateLength}" etv:targetWID="{$WorkerWID}">
								<xsl:value-of select="$BabyDueDate"/>
							</BabyDueDate>
							<LeaveStartDate etv:class="notReqWithWarn" etv:maxLength="{$LeaveStartDateLength}" etv:targetWID="{$WorkerWID}">
								<xsl:value-of select="$LeaveStartDate"/>
							</LeaveStartDate>
							<AbsenceType etv:class="notReqWithWarn" etv:maxLength="{$AbsenceTypeLength}" etv:targetWID="{$WorkerWID}">
								<xsl:value-of select="$AbsenceType"/>
							</AbsenceType>
							<OFPSchemeNo etv:class="notReqWithWarn" etv:maxLength="{$OFPSchemeNoLength}" etv:targetWID="{$WorkerWID}">
								<xsl:value-of select="$OFPSchemeNo"/>
							</OFPSchemeNo>
							<StartDateSMPPayments etv:class="notReqWithWarn" etv:maxLength="{$StartDateSMPPayments}" etv:targetWID="{$WorkerWID}">
								<xsl:value-of select="$StartDateSMPPayments"/>
							</StartDateSMPPayments>
							<EndDateSMPPayments etv:class="notReqWithWarn" etv:maxLength="{$EndDateSMPPaymentsLength}" etv:targetWID="{$WorkerWID}">
								<xsl:value-of select="$EndDateSMPPaymentsLength"/>
							</EndDateSMPPayments>
							<ReturnToWorkDate etv:class="notReqWithWarn" etv:maxLength="{$ReturnToWorkDateLength}" etv:targetWID="{$WorkerWID}">
								<xsl:value-of select="$ReturnToWorkDate"/>
							</ReturnToWorkDate>
						</Errors>
						
						<xsl:if test="1=1">
							<EEASPPBPeriodDetail>
								<xsl:if test="$BabyDueDate != ''">
									<xsl:attribute name="BabyDueDate">
										<xsl:value-of select="$BabyDueDate"/>
									</xsl:attribute>
								</xsl:if>
								<xsl:if test="$LeaveStartDate != ''">
									<xsl:attribute name="LeaveStartDate">
										<xsl:value-of select="$LeaveStartDate"/>
									</xsl:attribute>
								</xsl:if>
								<xsl:if test="$AbsenceType != ''">
									<xsl:attribute name="AbsenceType">
										<xsl:value-of select="$AbsenceType"/>
									</xsl:attribute>
								</xsl:if>
								<xsl:if test="$OFPSchemeNo != ''">
									<xsl:attribute name="OFPSchemeNo">
										<xsl:value-of select="$OFPSchemeNo"/>
									</xsl:attribute>
								</xsl:if>
								<xsl:if test="$StartDateSMPPayments != ''">
									<xsl:attribute name="StartDateSMPPayments">
										<xsl:value-of select="$StartDateSMPPayments"/>
									</xsl:attribute>
								</xsl:if>
								<xsl:if test="$EndDateSMPPayments != ''">
									<xsl:attribute name="EndDateSMPPayments">
										<xsl:value-of select="$EndDateSMPPayments"/>
									</xsl:attribute>
								</xsl:if>
								<xsl:if test="$ReturnToWorkDate != ''">
									<xsl:attribute name="ReturnToWorkDate">
										<xsl:value-of select="$ReturnToWorkDate"/>
									</xsl:attribute>
								</xsl:if>
							</EEASPPBPeriodDetail>
						</xsl:if>
					</xsl:if>
				</xsl:for-each>
			</Employee>
		</xsl:if>
	</xsl:template>

</xsl:stylesheet>
