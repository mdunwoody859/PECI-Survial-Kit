<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:peci="urn:com.workday/peci"
    exclude-result-prefixes="xs"
    version="3.0">
    <xsl:output indent="yes"/>
    
<!--    Store the current value of the Employee_ID so it can be written out when streaming child nodes-->
    <xsl:accumulator name="emp.id" streamable="yes" as="xs:string" initial-value="''">
        <xsl:accumulator-rule match="peci:Employee_ID/text()" select="."/>
    </xsl:accumulator>
    
<!--    Increment each time we hit a Effective_Change in order to return the total number-->
    <xsl:accumulator name="change.count" streamable="yes" as="xs:integer" initial-value="0">
        <xsl:accumulator-rule match="peci:Effective_Change" select="$value + 1"/>
    </xsl:accumulator>
    
    
    <!--    Set to true when we hit the start of peci:Compensation_Summary_in_Pay_Group_Frequency and false at the end
    Used to determine if the current node is a child of peci:Compensation_Summary_in_Pay_Group_Frequency-->
  <xsl:accumulator name="found.base.pay.parent" streamable="yes" as="xs:boolean" initial-value="false()">
      <xsl:accumulator-rule match="peci:Compensation_Summary_in_Pay_Group_Frequency" phase="start" select="true()"/>
      <xsl:accumulator-rule match="peci:Compensation_Summary_in_Pay_Group_Frequency" phase="end" select="false()"/>
  </xsl:accumulator>
    
    <!--    Each tme we hit peci:Total_Base_Pay, check if it is a child of  peci:Compensation_Summary_in_Pay_Group_Frequency and if so, add it's vaue-->
    <xsl:accumulator name="base.pay.total" streamable="yes" as="xs:double" initial-value="0">
        <xsl:accumulator-rule match="peci:Total_Base_Pay/text()" select="if (accumulator-after('found.base.pay.parent')) then $value + . else $value"/>
      </xsl:accumulator>
    
    
<!--    Count the number of times each peci:Compensation_Pan exists-->
    <xsl:accumulator name="comp.plan.map" as="map(xs:string,xs:integer)" initial-value="map{}" streamable="yes">
        <xsl:accumulator-rule match="peci:Compensation_Plan/text()">
            <xsl:variable name="new.value" select="if (map:contains($value,.)) then map:get($value,.)  else 0"/>
            <xsl:sequence select="map:put($value, xs:string(.), $new.value + 1)"/>
        </xsl:accumulator-rule>
    </xsl:accumulator>
    
    
    <!--   Store the current value of peci:Currency if it is a child of peci:Compensation_Summary_in_Pay_Group_Frequency-->
    <xsl:accumulator name="base.pay.currency" streamable="yes" as="xs:string" initial-value="''">
        <xsl:accumulator-rule match="peci:Currency/text()" select="if (accumulator-after('found.base.pay.parent')) then .  else ''"/>
    </xsl:accumulator>
    
    <!--   Store the current value of peci:Total_Base_Pay if it is a child of peci:Compensation_Summary_in_Pay_Group_Frequency-->
    <xsl:accumulator name="base.pay" streamable="yes" as="xs:double" initial-value="0">
        <xsl:accumulator-rule match="peci:Total_Base_Pay/text()" select="if (accumulator-after('found.base.pay.parent')) then xs:double(.) else 0"/>
    </xsl:accumulator>
    
    <!--Used to return the total amount of base pay for each currency    
        When at the end of peci:Compensation_Summary_in_Pay_Group_Frequency read the values back for currency and base pay
       Use currency as the map key and the base pay as the value
     -->
    <xsl:accumulator name="base.pay.by.country.map" as="map(xs:string,xs:double)" initial-value="map{}" streamable="yes">
        <xsl:accumulator-rule match="peci:Compensation_Summary_in_Pay_Group_Frequency" phase="end">
            <xsl:choose>
                <xsl:when test="accumulator-after('found.base.pay.parent')">
                    
                    <xsl:variable name="key" select="accumulator-after('base.pay.currency')"/>
                    <xsl:variable name="pay" select="accumulator-after('base.pay')"/>
                    <!--Check if the map contains an entry for currency
                    If it does not return 0
                    If it does, return the current value-->
                    <xsl:variable name="current.value" select="if (map:contains($value,$key)) then map:get($value,$key) else 0"/>
                    <xsl:sequence select="map:put($value, $key, $current.value + $pay)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="$value"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:accumulator-rule>
    </xsl:accumulator>
    
     
<!--    A mode with no name is the default-->
    <xsl:mode streamable="yes" on-no-match="shallow-skip" use-accumulators="emp.id change.count found.base.pay.parent base.pay.total base.pay.by.country.map base.pay.currency base.pay comp.plan.map"/>
    <xsl:mode streamable="no" name="in-memory"/>
    
    
     
    <xsl:template match="/">
        <root>
            
            <xsl:apply-templates/>
            
            <Footer>
               <Total_Changes><xsl:value-of select="accumulator-after('change.count')"/></Total_Changes>
               <Total_Base_Pay><xsl:value-of select="accumulator-after('base.pay.total')"/></Total_Base_Pay>
               
               <xsl:variable name="map" select="accumulator-after('comp.plan.map')"/>
               <Comp_Plans>
                 <xsl:for-each select="map:keys($map)">
                     <Plan>
                       <Name><xsl:value-of select="."/></Name>
                       <Count><xsl:value-of select="$map(.)"/></Count>
                     </Plan>
                 </xsl:for-each>
               </Comp_Plans>
               
               <xsl:variable name="map" select="accumulator-after('base.pay.by.country.map')"/>
               <Pay_By_Currency>
                   <xsl:for-each select="map:keys($map)">
                       <Currency>
                           <Code><xsl:value-of select="."/></Code>
                           <Base_Pay><xsl:value-of select="$map(.)"/></Base_Pay>
                       </Currency>
                   </xsl:for-each>
               </Pay_By_Currency>
            </Footer>
            
        </root>
    </xsl:template>
    
<!--    This template will be hit when streaming
    There is no need to have templates on any of the ancestors because we are using on-no-match="shallow-skip"
    -->
    <xsl:template match="peci:Compensation_Summary_in_Pay_Group_Frequency">
        <xsl:apply-templates select="copy-of()" mode="in-memory"/>
      </xsl:template>
    
    <xsl:template match="peci:Compensation_Summary_in_Pay_Group_Frequency" mode="in-memory">
         <Compensation>
            <EmpID><xsl:value-of select="accumulator-after('emp.id')"/></EmpID>
            <Base_Pay><xsl:value-of select="peci:Total_Base_Pay"/></Base_Pay>
            <Currency><xsl:value-of select="peci:Currency"/></Currency>
        </Compensation>
    </xsl:template>
    
</xsl:stylesheet>