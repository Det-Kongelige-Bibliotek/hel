<?xml version="1.0" encoding="UTF-8" ?>

<xsl:transform version="1.0"
	       xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	       xmlns:marc="http://www.loc.gov/MARC21/slim"
	       xmlns:xlink="http://www.w3.org/1999/xlink"
	       xmlns:exsl="http://exslt.org/common"
	       extension-element-prefixes="exsl">

  <xsl:param name="pdfUri"  select="'http://example.com/mock-file.pdf'" />

  <!-- http://biblstandard.dk/kat/konv_danmarc2_to_marc21.htm -->

  <xsl:output method="xml"
	      indent="yes"
	      encoding="UTF-8" />

  <xsl:template match="/">
    <marc:record>
      <xsl:apply-templates/>

      <!-- we shouldn't create this field unless we have a non-zero length
      $pdfUri -->

      <xsl:if test="$pdfUri">
	<xsl:element name="marc:datafield">
	  <xsl:attribute name="ind1">#</xsl:attribute>
	  <xsl:attribute name="ind2">1</xsl:attribute>
	  <xsl:attribute name="tag">856</xsl:attribute>
	  <xsl:element name="marc:subfield">
	    <xsl:attribute name="code">u</xsl:attribute>
	    <xsl:value-of select="$pdfUri"/>
	  </xsl:element>
	</xsl:element>
      </xsl:if>

    </marc:record>
  </xsl:template>

  <xsl:template match="present">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="record">
    <xsl:apply-templates/>
  </xsl:template>


  <xsl:template match="oai_marc">
    <xsl:apply-templates/>
  </xsl:template>


  <xsl:template match="varfield[@id='096']">

    <xsl:element name="marc:datafield">
      <xsl:attribute name="ind1">
	<xsl:value-of select="@i1"/>
      </xsl:attribute>
      <xsl:attribute name="ind2">
	<xsl:value-of select="@i1"/>
      </xsl:attribute>
      <xsl:attribute name="tag">852</xsl:attribute>
      <xsl:element name="marc:subfield">
	<xsl:attribute name="code">a</xsl:attribute>
	<xsl:value-of select="subfield[@label='a']"/>
      </xsl:element>
    </xsl:element>

  </xsl:template>

  <xsl:template match="varfield[@id='008']">
    <xsl:element name="marc:datafield">
      <xsl:attribute name="ind1">#</xsl:attribute>
      <xsl:attribute name="ind2">#</xsl:attribute>
      <xsl:attribute name="tag">041</xsl:attribute>
      <xsl:element name="marc:subfield">
        <xsl:attribute name="code">a</xsl:attribute>
        <xsl:value-of select="subfield[@label='l']"/>
      </xsl:element>
    </xsl:element>

  </xsl:template>

  <xsl:template match="varfield[@id='021']">
    <xsl:if test="subfield[@label='e']">
      <marc:datafield tag='020'>
	<xsl:attribute name="ind1">0</xsl:attribute><xsl:attribute name="ind2">0</xsl:attribute>
	<marc:subfield code="a"> 
	  <xsl:value-of select="subfield[@label='e']"/>
	</marc:subfield>
      </marc:datafield>
    </xsl:if>
  </xsl:template>

  <xsl:template match="varfield[@id='100']">

    <xsl:element name="marc:datafield">

      <xsl:attribute name="ind1">
	<xsl:value-of select="@i1"/>
      </xsl:attribute>
      <xsl:attribute name="ind2">
	<xsl:value-of select="@i2"/>
      </xsl:attribute>
      <xsl:attribute name="tag">
	<xsl:value-of select="@id"/>
      </xsl:attribute>

      <xsl:if test="subfield[@label = 'a']">
	<xsl:element name="marc:subfield">
	  <xsl:attribute name="code">a</xsl:attribute>
	  <xsl:value-of select="subfield[@label = 'a']"/><xsl:text>,
	  </xsl:text><xsl:value-of select="subfield[@label = 'h']"/>
	</xsl:element>
      </xsl:if>

      <xsl:call-template name="name-content" />

      <xsl:if test="subfield[@label='k']">
	<xsl:element name="marc:subfield">
	  <xsl:attribute name="code">q</xsl:attribute>
	  <xsl:for-each select="subfield[@label = 'a'] | subfield[@label = 'k']">
	    <xsl:if test="position() &gt; 1"><xsl:text>, </xsl:text></xsl:if><xsl:apply-templates/>
	  </xsl:for-each>
	</xsl:element>
      </xsl:if>

      <xsl:choose>
	<xsl:when test="subfield[@label = '4']">
	  <xsl:element name="marc:subfield">
	    <xsl:attribute name="code">4</xsl:attribute>
	    <xsl:value-of select="subfield[@label = '4']"/>
	  </xsl:element>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:element name="marc:subfield"><xsl:attribute name="code">4</xsl:attribute>aut</xsl:element>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:element>

  </xsl:template>

  <xsl:template match="varfield[@id='241']"> 
    <xsl:if test="subfield[@label='a']" >
      <xsl:element name="marc:datafield">
	<xsl:attribute name="tag">765</xsl:attribute>
	<xsl:attribute name="ind1">
	  <xsl:value-of select="@i1"/>
	</xsl:attribute>
	<xsl:attribute name="ind2">
	  <xsl:value-of select="@i2"/>
	</xsl:attribute>
	<xsl:element name="marc:subfield">
	  <xsl:attribute name="code">t</xsl:attribute>
	  <xsl:value-of select="subfield[@label='a']" />
	</xsl:element>
      </xsl:element>
    </xsl:if>
  </xsl:template>

  <xsl:template match="varfield[@id='245']">
    <xsl:variable name="ind2">
      <xsl:choose>
	<xsl:when test="starts-with(subfield[@label = 'a'],'&lt;&lt;') and
			not(contains(substring-before(subfield[@label = 'a'],'&gt;&gt;'),'='))">
	  <xsl:value-of
	      select="string-length(substring-after(substring-before(subfield[@label = 'a'][1],'&gt;&gt;'),'&lt;&lt;'))"/>
	</xsl:when>
	<xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="subfieldA">
      <xsl:apply-templates select="subfield[@label = 'a'][1]"/>
    </xsl:variable>

    <xsl:element name="marc:datafield">
      <xsl:attribute name="ind1">
	<xsl:value-of select="@i1"/>
      </xsl:attribute>
      <xsl:attribute name="ind2">
	<xsl:value-of select="$ind2"/>
      </xsl:attribute>
      <xsl:attribute name="tag">
	<xsl:value-of select="@id"/>
      </xsl:attribute>

      <xsl:element name="marc:subfield">
	<xsl:attribute name="code">a</xsl:attribute>
	<xsl:value-of select="$subfieldA"/>
	<xsl:if test="subfield[@label = 'b']">
	  <xsl:text> </xsl:text><xsl:apply-templates select="subfield[@label = 'b']"/>
	</xsl:if>
      </xsl:element>

      <xsl:element name="marc:subfield">
	<xsl:attribute name="code">b</xsl:attribute>

	<xsl:for-each select="subfield[@label = 'a'][position() &gt; 1]">
	  <xsl:text>; </xsl:text><xsl:apply-templates select="."/>
	</xsl:for-each>

	<xsl:for-each select="subfield[@label = 'c'] | subfield[@label = 'u']">
	  <xsl:text> </xsl:text><xsl:apply-templates/>
	  <xsl:if test="following-sibling::subfield[@label = 'p']">
	    <xsl:text>=</xsl:text><xsl:apply-templates select="following-sibling::subfield[@label = 'p']"/>
	  </xsl:if>
	</xsl:for-each>
      </xsl:element>

      <xsl:element name="marc:subfield">
	<xsl:attribute name="code">c</xsl:attribute>

	<xsl:for-each select="subfield[@label = 'e'] |
			      subfield[@label = 'f'] |
			      subfield[@label = 'i'] |
			      subfield[@label = 'j'] |
			      subfield[@label = 'æ'] |
			      subfield[@label = 't']">

	  <xsl:choose>
	    <xsl:when test="contains('efij',@label)"><xsl:text> </xsl:text><xsl:apply-templates select="."/></xsl:when>
	    <xsl:otherwise><xsl:text>=</xsl:text><xsl:apply-templates select="."/></xsl:otherwise>
	  </xsl:choose>
	</xsl:for-each>
      </xsl:element>

    </xsl:element>
  </xsl:template>

  <xsl:template match="varfield[@id='247' or @id='248']">
    <xsl:if test="subfield[@label='a']">
      <xsl:element name="marc:datafield">
	<xsl:attribute name="ind1">
	  <xsl:value-of select="@i1"/>
	</xsl:attribute>
	<xsl:attribute name="ind2">
	  <xsl:value-of select="@i1"/>
	</xsl:attribute>
	<xsl:attribute name="tag">505</xsl:attribute>

	<xsl:for-each select="subfield[@label='a' or @label='g']">
	  <xsl:element name="marc:subfield">
	    <xsl:choose>
	      <xsl:when test="@label='a'">
		<xsl:attribute name="code">t</xsl:attribute>
	      </xsl:when>
	      <xsl:when test="@label='g'">
		<xsl:attribute name="code">t</xsl:attribute>
	      </xsl:when>
	    </xsl:choose>
	    <xsl:value-of select="translate(.,'[].:;','')"/>
	    <xsl:if test="position() = last"><xsl:text> -- </xsl:text></xsl:if>
	  </xsl:element>
	</xsl:for-each>

      </xsl:element>
    </xsl:if>
  </xsl:template>


  <xsl:template match="varfield[@id='260']">
    <xsl:element name="marc:datafield">
      <xsl:attribute name="ind1">
	<xsl:value-of select="@i1"/>
      </xsl:attribute>
      <xsl:attribute name="ind2">
	<xsl:value-of select="@i1"/>
      </xsl:attribute>
      <xsl:attribute name="tag">
	<xsl:value-of select="@id"/>
      </xsl:attribute>

      <xsl:if test="subfield[@label='a']">
	<xsl:for-each select="subfield[@label='a']">
	  <xsl:element name="marc:subfield">
	    <xsl:attribute name="code">a</xsl:attribute>
	    <xsl:if test="position() &gt; 1"><xsl:text>; </xsl:text></xsl:if>
	    <xsl:value-of select="translate(.,'[].:;','')"/>
	  </xsl:element>
	</xsl:for-each>
      </xsl:if>


      <xsl:if test="//varfield[@id='008'][subfield[@label='a']]">	
	<xsl:element name="marc:subfield">
	  <xsl:attribute name="code">c</xsl:attribute>
	  <xsl:value-of select="../varfield[@id='008']/subfield[@label='a']"/>	
	</xsl:element>
      </xsl:if>

      <xsl:for-each select="subfield[@label='b'] |
	                    subfield[@label='f'] |
	                    subfield[@label='g']">
	<xsl:element name="marc:subfield">
	  <xsl:attribute name="code">
	    <xsl:choose>
	      <xsl:when test="@label='b'">b</xsl:when>
	      <xsl:when test="@label='f'">a</xsl:when>
	      <xsl:when test="@label='g'">b</xsl:when>
	    </xsl:choose>
	  </xsl:attribute>
	  <xsl:if test="position()&gt;1">
	    <xsl:choose>
	      <xsl:when test="contains('bg',@label)"><xsl:text>: </xsl:text></xsl:when>
	      <xsl:when test="@label = 'c'"> </xsl:when>
	      <xsl:when test="@label = 'g'"><xsl:text>; </xsl:text></xsl:when>
	    </xsl:choose>
	  </xsl:if><xsl:apply-templates select="."/>
	</xsl:element>
      </xsl:for-each>

      <xsl:for-each select="subfield[@label='r'] |
	                    subfield[@label='t'] |
	                    subfield[@label='j']">
	<xsl:element name="marc:subfield">
	  <xsl:attribute name="code">
	    <xsl:choose>
	      <xsl:when test="@label='r'">e</xsl:when>
	      <xsl:when test="@label='t'">f</xsl:when>
	      <xsl:when test="@label='j'">g</xsl:when>
	    </xsl:choose>
	  </xsl:attribute>
	  <xsl:if test="position()=1">(</xsl:if>
	  <xsl:if test="@label='t' and position()=2"> :</xsl:if>
	  <xsl:if test="@label='g' and position()&gt;=2">,</xsl:if>
	  <xsl:apply-templates select="."/>
	  <xsl:if test="position()=last()">)</xsl:if>
	</xsl:element>
      </xsl:for-each>
    </xsl:element>
  </xsl:template>

  <xsl:template match="varfield[@id='520']">
    <xsl:element name="marc:datafield">
      <xsl:choose>
	<xsl:when test="contains('itedxb',subfield/@label)"> 
	  <xsl:attribute name="ind1"> </xsl:attribute>
	  <xsl:attribute name="ind2"> </xsl:attribute>
	  <xsl:attribute name="tag">534</xsl:attribute>
	  <xsl:for-each select="subfield">
	    <xsl:element name="marc:subfield">
	      <xsl:choose>
		<xsl:when test="@label='a'">
		  <xsl:attribute name="code">p</xsl:attribute>
		</xsl:when>
		<xsl:when test="@label='i'">
		  <xsl:attribute name="code">p</xsl:attribute>
		</xsl:when>
		<xsl:when test="@label='t'">
		  <xsl:attribute name="code">t</xsl:attribute>
		</xsl:when>
		<xsl:when test="@label='d'">
		  <xsl:attribute name="code">a</xsl:attribute>
		</xsl:when>
	      </xsl:choose>
	      <xsl:apply-templates/>
	    </xsl:element>
	  </xsl:for-each>
	</xsl:when>
	<xsl:when test="not(contains('itedxb',subfield/@label)) and contains('a',subfield/@label)">
	  <xsl:attribute name="ind1"> </xsl:attribute>
	  <xsl:attribute name="ind2"> </xsl:attribute>
	  <xsl:attribute name="tag">500</xsl:attribute>
	  <xsl:element name="marc:subfield">
	    <xsl:attribute name="code">a</xsl:attribute>
	    <xsl:apply-templates/>
	  </xsl:element>
	</xsl:when>
      </xsl:choose>
    </xsl:element>
  </xsl:template>

  <xsl:template match="varfield[@id='529']">
    <xsl:element name="marc:datafield">
      <xsl:attribute name="ind1">1</xsl:attribute>
      <xsl:attribute name="ind2"> </xsl:attribute>
      <xsl:attribute name="tag">856</xsl:attribute>

      <xsl:for-each select="subfield[@label='b']">
	<xsl:element name="marc:subfield">
	  <xsl:attribute name="code">c</xsl:attribute>
	  <xsl:apply-templates/>
	</xsl:element>
      </xsl:for-each>

      <xsl:element name="marc:subfield">
	<xsl:attribute name="code">z</xsl:attribute><xsl:text>cover image</xsl:text>
      </xsl:element>

      <xsl:for-each select="subfield[@label='u']">
	<xsl:element name="marc:subfield">
	  <xsl:attribute name="code"><xsl:value-of select="@label"/></xsl:attribute>
	  <xsl:apply-templates/>
	</xsl:element>
      </xsl:for-each>

    </xsl:element>
  </xsl:template>

  <xsl:template name="name-content">
    <xsl:if test="subfield[@label = 'a'] |
		  subfield[@label = 'h']">

      <xsl:processing-instruction name="family"><xsl:value-of select="subfield[@label = 'a']"/></xsl:processing-instruction>
      
      <xsl:processing-instruction name="given"><xsl:value-of select="subfield[@label = 'h']"/></xsl:processing-instruction>

      <xsl:element name="marc:subfield">
	<xsl:attribute name="code">a</xsl:attribute>
	<xsl:value-of select="subfield[@label = 'a']"/>,
	<xsl:value-of select="subfield[@label = 'h']"/>
      </xsl:element>
    </xsl:if>

    <xsl:for-each select="subfield[not(contains('ah',@label))]">
      <xsl:element name="marc:subfield">
	<xsl:attribute name="code">
	  <xsl:value-of select="translate(@label,'ecfkb','bdcqe')"/>
	</xsl:attribute>
	<xsl:apply-templates/>
      </xsl:element>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="varfield[@id='600']">
    <xsl:element name="marc:datafield">
      <xsl:call-template name="indicators"/>
      <xsl:call-template name="name-content" />
    </xsl:element>
  </xsl:template>

  <xsl:template match="varfield[@id='700']">
    <xsl:element name="marc:datafield">
      <xsl:choose>
	<xsl:when test="subfield/@label='h'">
	  <xsl:attribute name="ind1">1</xsl:attribute>
	  <xsl:attribute name="ind2"><xsl:text>#</xsl:text></xsl:attribute>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:attribute name="ind1">0</xsl:attribute>
	  <xsl:attribute name="ind2"><xsl:text>#</xsl:text></xsl:attribute>
	</xsl:otherwise>
      </xsl:choose>

      <xsl:attribute name="tag">700</xsl:attribute>

      <xsl:call-template name="name-content" />

      <xsl:if test="subfield[@label = '4']">
	<xsl:element name="marc:subfield">
	  <xsl:attribute name="code">4</xsl:attribute>
	  <xsl:value-of select="subfield[@label = '4']"/>
	</xsl:element>
      </xsl:if>


    </xsl:element>
  </xsl:template>

  
  <xsl:template match="varfield[@id='720']">
    <xsl:element name="marc:datafield">
      <xsl:attribute name="tag">
	<xsl:value-of select="@id"/>
      </xsl:attribute>
      <xsl:if test="subfield[@label = 'o']">
	<xsl:element name="marc:subfield">
	  <xsl:attribute name="code">a</xsl:attribute>
	  <xsl:value-of select="subfield[@label = 'o']"/>
	</xsl:element>
      </xsl:if>
      <xsl:if test="subfield[@label = '4']">
	<xsl:element name="marc:subfield">
	  <xsl:attribute name="code">4</xsl:attribute>
	  <xsl:value-of select="subfield[@label = '4']"/>
	</xsl:element>
      </xsl:if>
    </xsl:element>
  </xsl:template>


  <xsl:template match="varfield">
    <xsl:element name="marc:datafield">
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <xsl:template name="indicators">
    <xsl:attribute name="ind1">
      <xsl:value-of select="@i1"/>
    </xsl:attribute>
    <xsl:attribute name="ind2">
      <xsl:value-of select="@i1"/>
    </xsl:attribute>
    <xsl:attribute name="tag">
      <xsl:value-of select="@id"/>
    </xsl:attribute>
  </xsl:template>


  <xsl:template match="subfield">
    <xsl:element name="marc:subfield">
      <xsl:attribute name="code">
	<xsl:value-of select="@label"/>
      </xsl:attribute>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="text()">

    <!-- taking care of &lt;&lt;Bakkeskraaning=bakkeskråning&gt;&gt; -->

    <xsl:choose>
      <xsl:when test="starts-with(.,'&lt;&lt;') and 
			not(contains(substring-before(.,'&gt;&gt;'),'='))">
	<xsl:value-of
	    select="substring-after(substring-before(.,'&gt;&gt;'),'&lt;&lt;')"/>
	<xsl:variable name="therest">
	  <the-rest>
	    <xsl:value-of select="substring-after(.,'&gt;&gt;')"/>
	  </the-rest>
	</xsl:variable>
	<xsl:apply-templates select="exsl:node-set($therest)/the-rest"/>
      </xsl:when>

      <xsl:when test="contains(substring-before(substring-after(.,'&lt;&lt;'),'&gt;&gt;'),'=')">
	<xsl:value-of select="substring-before(.,'&lt;&lt;')"/>
	<xsl:value-of select="substring-before(substring-after(.,'&lt;&lt;'),'=')"/>
	<xsl:variable name="therest">
	  <the-rest>
	    <xsl:value-of select="substring-after(.,'&gt;&gt;')"/>
	  </the-rest>
	</xsl:variable>
	<xsl:apply-templates select="exsl:node-set($therest)/the-rest"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="."/>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <xsl:template match="session-id|record_header|doc_number"/>


</xsl:transform>
