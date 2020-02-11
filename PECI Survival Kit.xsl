<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="3.0">
    
    <!--
    Kainos Software Ltd PECI Survival Kit
    Version 0.1
    Authors: Michael Dunwoody, Sarah Quinn, Zoe Bambrick
    -->
    
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- Template for whenever scenario x is encountered -->
    <xsl:template match = "node()">
        
    </xsl:template>
    
</xsl:stylesheet>