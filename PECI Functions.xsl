<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:peci="urn:com.workday/peci"
    exclude-result-prefixes="xs"
    version="2.0">
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