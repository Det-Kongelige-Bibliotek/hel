<?xml version="1.0" encoding="UTF-8" ?>
<!--

Author Sigfrid Lundberg slu@kb.dk

-->
<xsl:transform version="1.0"
	       xmlns:t="http://www.tei-c.org/ns/1.0"
	       xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 

	       exclude-result-prefixes="t">

  <xsl:output omit-xml-declaration="yes"
	      encoding="UTF-8"
	      method="xml"/>



  <xsl:param 
      name="submixion" 
      select="''"/>
   
  <xsl:param 
      name="id"  
      select="''"/>

  <xsl:param 
      name="doc" 
      select="''"/>

  <xsl:param 
      name="hostname" 
      select="''"/>

  <xsl:param 
      name="file" 
      select="''"/>

  <xsl:param 
      name="status" 
      select="''"/>

 <xsl:template match="/">
   <json type="object">
     <xsl:choose>
       <xsl:when test="$id">
	 <xsl:for-each select="//node()[$id=@xml:id]">
	   <xsl:call-template name="formulate"/>
	 </xsl:for-each>
       </xsl:when>
       <xsl:otherwise>
	 <pair name="error" type="string">No id given</pair>
       </xsl:otherwise>
     </xsl:choose>
   </json>
  </xsl:template>

  <xsl:template name="formulate">

      <xsl:call-template name="mk_input">
	<xsl:with-param name="name">file</xsl:with-param>
	<xsl:with-param name="value">
	  <xsl:value-of select="$file"/>
	</xsl:with-param>
	<xsl:with-param name="type">string</xsl:with-param>
      </xsl:call-template>

      <xsl:call-template name="mk_input">
	<xsl:with-param name="name">id</xsl:with-param>
	<xsl:with-param name="value">
	  <xsl:value-of select="@xml:id"/>
	</xsl:with-param>
	<xsl:with-param name="type">string</xsl:with-param>
      </xsl:call-template>

      <xsl:if test="descendant::t:persName[@type='sender']">	
	<pair name="sender" type="array">
	  <xsl:for-each select="descendant::t:persName[@type='sender']">	
	    <xsl:call-template name="mk_field">
	      <xsl:with-param name="name">text</xsl:with-param>
	    </xsl:call-template>
	  </xsl:for-each>
	</pair>
      </xsl:if>

      <xsl:if test="descendant::t:persName[@type='recipient']">	
	<pair name="recipient" type="array">
	  <xsl:for-each select="descendant::t:persName[@type='recipient']">
	    <xsl:call-template name="mk_field">
	      <xsl:with-param name="name">text</xsl:with-param>
	    </xsl:call-template>
	  </xsl:for-each>
	</pair>
      </xsl:if>

      <xsl:if test="descendant::t:geogName">	
	<pair name="place" type="array">
	  <xsl:for-each select="descendant::t:geogName">
	    <xsl:call-template name="mk_field">
	      <xsl:with-param name="name">text</xsl:with-param>
	    </xsl:call-template>
	  </xsl:for-each>
	</pair>
      </xsl:if>
     
      <xsl:if test="descendant::t:date">
	<pair name="date" type="object">
	  <xsl:for-each select="descendant::t:date[1]">
	    <xsl:call-template name="mk_input">
	      <xsl:with-param name="name">text</xsl:with-param>
	      <xsl:with-param name="value">
		<xsl:value-of select="."/>
	      </xsl:with-param>
	    </xsl:call-template>
	    <xsl:call-template name="mk_input">
	      <xsl:with-param name="name" select="'id'"/>
	      <xsl:with-param name="value">
		<xsl:value-of select="@xml:id"/>
	      </xsl:with-param>
	      <xsl:with-param name="type">pair</xsl:with-param>
	    </xsl:call-template>
	  </xsl:for-each>
	</pair>
      </xsl:if>

  </xsl:template>

  <xsl:template name="mk_field">
    <xsl:param name="name"    select="''"/>

    <xsl:element name="item">
      <xsl:attribute name="type">object</xsl:attribute>
      <xsl:call-template name="mk_input">
	<xsl:with-param name="name">
	  <xsl:value-of select="$name"/>
	</xsl:with-param>
	<xsl:with-param name="value">
	  <xsl:value-of select="."/>
	</xsl:with-param>
	<xsl:with-param name="type">pair</xsl:with-param>
      </xsl:call-template>

      <xsl:call-template name="mk_input">
	<xsl:with-param name="name" select="'id'"/>
	<xsl:with-param name="value">
	  <xsl:value-of select="@xml:id"/>
	</xsl:with-param>
	<xsl:with-param name="type">pair</xsl:with-param>
      </xsl:call-template>
    </xsl:element>

  </xsl:template>

  <xsl:template name="mk_input">
    <xsl:param name="name" select="''"/>
    <xsl:param name="value" select="''"/>
    <xsl:param name="type" select="'pair'"/>

    <xsl:element name="pair">
      <xsl:attribute name="type">
	<xsl:value-of select="$type"/>
      </xsl:attribute>
      <xsl:attribute name="name">
	<xsl:value-of select="$name"/>
      </xsl:attribute>
      <xsl:value-of select="$value"/>
    </xsl:element>
  </xsl:template>


</xsl:transform>
