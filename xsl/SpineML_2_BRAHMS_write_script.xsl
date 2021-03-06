<?xml version="1.0" encoding="ISO-8859-1"?><xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:SMLLOWNL="http://www.shef.ac.uk/SpineMLLowLevelNetworkLayer" xmlns:SMLNL="http://www.shef.ac.uk/SpineMLNetworkLayer" xmlns:SMLCL="http://www.shef.ac.uk/SpineMLComponentLayer" xmlns:NMLEX="http://www.shef.ac.uk/SpineMLExperimentLayer" xmlns:fn="http://www.w3.org/2005/xpath-functions">
<xsl:output method="text" version="1.0" encoding="UTF-8" indent="yes"/>

<!-- Note that the param is outside the template, but is used inside the template. -->
<xsl:param name="hostos" select="'unknown'" />

<xsl:template match="/">
<!-- THIS IS A NON-PLATFORM SPECIFIC XSLT SCRIPT THAT GENERATES THE BASH SCRIPT TO CREATE
     THE PROCESSES / SYSTEM -->
<!-- VERSION = LINUX OR OSX -->

<!-- To produce output for either Linux32/64 or Mac OS, we use a parameter, passed in,
     called hostos which is used to set the compiler flags, include paths and linker flags,
     as applicable. -->
<xsl:variable name="compiler_flags">
    <xsl:if test="$hostos='Linux32' or $hostos='Linux64'">-fPIC -Werror -pthread -O3 -shared -D__GLN__</xsl:if>
    <xsl:if test="$hostos='OSX'">-undefined dynamic_lookup -fvisibility=hidden -fvisibility-inlines-hidden -arch x86_64 -D__OSX__ -fPIC -O3 -dynamiclib</xsl:if>
</xsl:variable>

<!-- this could go - there's no longer a need to link against
     libbrahms-engine on any platform -->
<xsl:variable name="linker_flags">
    <!-- <xsl:if test="$hostos='OSX'">-L`brahms \-\-showlib`</xsl:if> -->
</xsl:variable>

<xsl:variable name="component_output_file">
    <xsl:if test="$hostos='Linux32' or $hostos='Linux64'">component.so</xsl:if>
    <xsl:if test="$hostos='OSX'">component.dylib</xsl:if>
</xsl:variable>

<xsl:variable name="platform_specific_includes">
    <xsl:if test="$hostos='Linux32' or $hostos='Linux64'">-I`brahms --showinclude` -I`brahms --shownamespace`</xsl:if>
</xsl:variable>

<!-- since we start in the experiment file we need to use for-each to get to the model file -->
<xsl:variable name="model_xml" select="//NMLEX:Model/@network_layer_url"/>
<xsl:for-each select="document(//NMLEX:Model/@network_layer_url)">

<xsl:choose>

<!-- SpineML low level network layer: START SMLLOWNL SECTION -->
<xsl:when test="SMLLOWNL:SpineML">#!/bin/bash
REBUILD_COMPONENTS=$1
REBUILD_SYSTEMML=$2
MODEL_DIR=$3 <!-- The model to work from. Probably equal to $OUTPUT_DIR_BASE/model -->
INPUT=$4 <!-- always experiment.xml -->
BRAHMS_NS=$5
SPINEML_2_BRAHMS_DIR=$6
OUTPUT_DIR_BASE=$7 <!-- The base directory of the output directory tree. -->
XSL_SCRIPT_PATH=$8
VERBOSE_BRAHMS=${9}
NODES=${10} <!-- Number of machine nodes to use. If >1, then this assumes we're using Sun Grid Engine. -->
NODEARCH=${11}
BRAHMS_NOGUI=${12}
<!--
    Here's a variable that can be set to avoid the component testing
    from going ahead. This may be useful when you are running your sim
    many times and you don't want the component check to happen each
    time; it may take a few seconds for large models. If you prefer
    NOT to assume components are present, then set this blank.
    -->
ASSUME_COMPONENTS_PRESENT=${13}

echo "VERBOSE_BRAHMS: $VERBOSE_BRAHMS"

<!-- Test brahms version -->
BRAHMS_VERSION=`brahms --ver`
VERSION_BRAHMS_MAJ=`echo $BRAHMS_VERSION | awk -F'.' '{print $1}'`
VERSION_BRAHMS_MIN=`echo $BRAHMS_VERSION | awk -F'.' '{print $2}'`
VERSION_BRAHMS_REL=`echo $BRAHMS_VERSION | awk -F'.' '{print $3}'`
VERSION_BRAHMS_REV=`echo $BRAHMS_VERSION | awk -F'.' '{print $4}'`
VERSION_TOO_OLD=0
if [ $VERSION_BRAHMS_MAJ -ge 0 ]; then
  echo "VERSION_BRAHMS_MAJ=$VERSION_BRAHMS_MAJ: ok"
  if [ $VERSION_BRAHMS_MIN -ge 8 ]; then
    echo "VERSION_BRAHMS_MIN=$VERSION_BRAHMS_MIN: ok"
    if [ $VERSION_BRAHMS_REL -ge 0 ]; then
      echo "VERSION_BRAHMS_REL=$VERSION_BRAHMS_REL: ok"
      if [ $VERSION_BRAHMS_REV -ge 1 ]; then
        echo "VERSION_BRAHMS_REV=$VERSION_BRAHMS_REV: ok"
      else # 1
        VERSION_TOO_OLD=1
      fi
    else # 2
      VERSION_TOO_OLD=1
    fi
  else # 3
    VERSION_TOO_OLD=1
  fi
else # 4
  VERSION_TOO_OLD=1
fi

if [ x"$VERSION_TOO_OLD" = "x"1 ]; then
  echo "This version of SpineML_2_BRAHMS requires BRAHMS version 0.8.0.1 or greater. Exiting."
  exit 1
fi
<!-- Completed test of brahms version -->

echo "NODES: $NODES"
echo "NODEARCH: $NODEARCH"

if [ "x$VERBOSE_BRAHMS" = "xno" ]; then
  VERBOSE_BRAHMS=""
fi

if [ "x$NODES" = "x" ]; then
  NODES=0
fi

<!-- Is user requesting specific architecture? -->
if [ "x$NODEARCH" = "xamd" ]; then
  NODEARCH="-l arch=amd*"
elif [ "x$NODEARCH" = "xintel" ]; then
  NODEARCH="-l arch=intel*"
else
  echo "Ignoring invalid node architecture '$NODEARCH'"
  NODEARCH=""
fi

<!-- Are we in Sun Grid Engine mode? -->
if [[ "$NODES" -gt 0 ]]; then
  echo "Submitting execution Sun Grid Engine with $NODES nodes."
fi

<!-- Working directory - need to pass this to xsl scripts as we no
     longer have them inside the current working tree. -->
echo "SPINEML_2_BRAHMS_DIR is $SPINEML_2_BRAHMS_DIR"

<!-- Some paths need to be URL encoded. -->
rawurlencode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""

  for (( pos=0 ; pos&lt;strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}"
}

<!-- All brahms files go in a "run" subdirectory - sys.xml, sys-exe.xml, and so on.. -->
<!-- Update - this is SPINEML_RUN_DIR -->
SPINEML_RUN_DIR="$OUTPUT_DIR_BASE/run"
<!-- Ensure output dir exists -->
mkdir -p "$SPINEML_RUN_DIR"

<!-- Make percent encoded version of SPINEML_RUN_DIR, with %20 for a space etc. Necessary as
     SPINEML_RUN_DIR is passed to xsl's document() function -->
SPINEML_RUN_DIR_PERCENT_ENCODED=$(rawurlencode "$SPINEML_RUN_DIR")

<!-- The dir for component logs. Because log is always ../log wrt
     SPINEML_RUN_DIR, we don't actually pass this to any XSL. -->
SPINEML_LOG_DIR="$OUTPUT_DIR_BASE/log"
SPINEML_LOG_DIR_PERCENT_ENCODED=$(rawurlencode "$SPINEML_LOG_DIR")
mkdir -p "$SPINEML_LOG_DIR"

<!-- A code dir. - for debugging -->
SPINEML_CODE_DIR="$SPINEML_RUN_DIR/code"
mkdir -p "$SPINEML_CODE_DIR"
<!-- A counter for the code files - so we can save copies of all the component code files. -->
CODE_NUM="0"

<!-- The model dir is passed to xsl scripts, but it's used in such a way
     that we DON'T want a percent encoded version -->

<!--
A note about Namespaces

A Brahms installation will exist along with a SpineML_2_BRAHMS installation.
Each installation may have its own namespace, and these are referred to here
as BRAHMS_NS and SPINEML_2_BRAHMS_NS.

All SpineML_2_BRAHMS components are compiled and held in the SPINEML_2_BRAHMS_NS
The BRAHMS_NS contains the Brahms components, as distributed either as the Debian
package or the Brahms binary package. Both namespaces are passed to the brahms call.
-->
SPINEML_2_BRAHMS_NS="$SPINEML_2_BRAHMS_DIR/Namespace"
echo "SPINEML_2_BRAHMS_NS is $SPINEML_2_BRAHMS_NS"
echo "BRAHMS_NS is $BRAHMS_NS"

<!--
 Debugging. Set DEBUG to "true" to add the -g flag to your compile commands so that
 the components will be gdb-debuggable.

 With debuggable components, you can run them using a brahms script
 which calls brahms-execute via valgrind, which is very useful. To do
 that, find your brahms script (`which brahms` will tell you this) and
 make a copy of it, perhaps called brahms-vg. Now modify the way
 brahms-vg calls brahms-execute (prepend valgrind). Now change
 BRAHMS_CMD below so it calls brahms-vg, instead of brahms.
-->
DEBUG="false"

DBG_FLAG=""
if [ $DEBUG = "true" ]; then
# Add -g to compiler flags
DBG_FLAG="-g"
fi

<!-- We have enough information at this point in the script to build our BRAHMS_CMD: -->

BRAHMS_CMD="brahms $VERBOSE_BRAHMS $BRAHMS_NOGUI --par-NamespaceRoots=\"$BRAHMS_NS:$SPINEML_2_BRAHMS_NS:$SPINEML_2_BRAHMS_DIR/tools\" \"$SPINEML_RUN_DIR/sys-exe.xml\""


<!--
 If we're in "Sun Grid Engine mode", we can submit our brahms execution scripts
 to the Sun Grid Engine. For each node:
 1. Write out the script (in our SPINEML_RUN_DIR).
 2. qsub it.
-->
if [[ "$NODES" -gt 0 ]]; then # Sun Grid Engine mode

  <!-- Ensure sys-exe.xml is not present to begin with: -->
  rm -f "$SPINEML_RUN_DIR/sys-exe.xml"

  <!-- For each node: -->
  for (( NODE=1; NODE&lt;=$NODES; NODE++ )); do
    echo "Writing run_brahms qsub shell script: $SPINEML_RUN_DIR/run_brahms_$NODE.sh for node $NODE of $NODES"
    cat &gt; "$SPINEML_RUN_DIR/run_brahms_$NODE.sh" &lt;&lt;EOF
#!/bin/sh
#$  -l mem=8G -l h_rt=04:00:00 $NODEARCH
# First, before executing brahms, this script must find out its IP address and write this into a file.

# Obtain first IPv4 address from an eth device.

MYIP=\`ip addr show|grep eth[0-9]|grep inet | awk -F ' ' '{print \$2}' | awk -F '/' '{print \$1}' | head -n1\`
echo "\$MYIP" &gt; "$SPINEML_RUN_DIR/brahms_$NODE.ip"

# Now wait until sys-exe.xml has appeared
while [ ! -f "$SPINEML_RUN_DIR/sys-exe.xml" ]; do
  sleep 1
done

# Finally, can run brahms
cd "$SPINEML_RUN_DIR"
BRAHMS_CMD="brahms $VERBOSE_BRAHMS --par-NamespaceRoots=\"$BRAHMS_NS:$SPINEML_2_BRAHMS_NS:$SPINEML_2_BRAHMS_DIR/tools\" \"$SPINEML_RUN_DIR/sys-exe.xml\" --voice-$NODE"
eval \$BRAHMS_CMD
EOF

  qsub "$SPINEML_RUN_DIR/run_brahms_$NODE.sh"
done
fi

# Set up the include path for rng.h and impulse.h
if [ -f /usr/include/spineml-2-brahms/rng.h ]; then
    # In this case, it looks like the user has the debian package
    SPINEML_2_BRAHMS_INCLUDE_PATH=/usr/include/spineml-2-brahms
else
    # Use a path relative to SPINEML_2_BRAHMS_DIR
    SPINEML_2_BRAHMS_INCLUDE_PATH="$SPINEML_2_BRAHMS_DIR/include"
fi
echo "SPINEML_2_BRAHMS_INCLUDE_PATH=$SPINEML_2_BRAHMS_INCLUDE_PATH"

# Set up the path to the "tools" directory.

# exit on first error
#set -e
if [ "$REBUILD_COMPONENTS" = "true" ]; then
echo "Removing existing components in advance of rebuilding..."
# clean up the temporary dirs - we don't want old component versions lying around!
rm -R "$SPINEML_2_BRAHMS_NS/dev/SpineML/temp"/* &amp;&gt; /dev/null
fi

if [ ! x"${ASSUME_COMPONENTS_PRESENT}" = "x" ]; then
echo "DANGER:"
echo "DANGER: output.script is ASSUMING that all SpineML components have been built!"
echo "DANGER: (you would want to do this if running the model over and over with a batch script)"
echo "DANGER:"
fi

if [ x"${ASSUME_COMPONENTS_PRESENT}" = "x" ]; then

echo "Creating the Neuron populations..."

<xsl:for-each select="/SMLLOWNL:SpineML/SMLLOWNL:Population">
# Also update time.txt for SpineCreator / other tools
echo "*Compiling neuron <xsl:value-of select="position()"/> / <xsl:value-of select="count(/SMLLOWNL:SpineML/SMLLOWNL:Population)"/>" &gt; $MODEL_DIR/time.txt
<xsl:choose>
<xsl:when test="./SMLLOWNL:Neuron/@url = 'SpikeSource'">
echo "SpikeSource, skipping compile"
</xsl:when>
<xsl:otherwise>
<xsl:variable name="linked_file" select="document(./SMLLOWNL:Neuron/@url)"/>
<!-- Here we use the population number to determine which Neuron type we are outputting -->
<xsl:variable name="number"><xsl:number count="/SMLLOWNL:SpineML/SMLLOWNL:Population" format="1"/></xsl:variable>
echo "&lt;Number&gt;<xsl:value-of select="$number"/>&lt;/Number&gt;" &amp;&gt; "$SPINEML_RUN_DIR/counter.file"

DIRNAME=&quot;$SPINEML_2_BRAHMS_NS/dev/SpineML/temp/NB/<xsl:value-of select="translate($linked_file/SMLCL:SpineML/SMLCL:ComponentClass/@name,' -', 'oH')"/>/brahms/0&quot;
CODE_NUM=$((CODE_NUM+1))
diff -q &quot;$MODEL_DIR/<xsl:value-of select="./SMLLOWNL:Neuron/@url"/>&quot; &quot;$DIRNAME/<xsl:value-of select="./SMLLOWNL:Neuron/@url"/>&quot; &amp;&gt; /dev/null
<!-- Check if the component exists and has changed -->
if [ $? == 0 ] &amp;&amp; [ -f &quot;$DIRNAME/component.cpp&quot; ] &amp;&amp; [ -f &quot;$DIRNAME/<xsl:value-of select="$component_output_file"/>&quot; ]; then
echo "Component for population <xsl:value-of select="$number"/> exists, skipping ($DIRNAME/component.cpp)"
<!-- but copy the component into our code folder -->
cp &quot;$DIRNAME/component.cpp&quot; &quot;$SPINEML_CODE_DIR/component$CODE_NUM.cpp&quot;
else
echo "Creating component.cpp for population <xsl:value-of select="$number"/> ($DIRNAME/component.cpp)"
<!-- output_dir passed to concat() and document() functions in SpineML_2_BRAHMS_CL_neurons.xsl so must be % encoded. -->
xsltproc -o "$SPINEML_CODE_DIR/component$CODE_NUM.cpp" --stringparam spineml_run_dir "$SPINEML_RUN_DIR_PERCENT_ENCODED" "$XSL_SCRIPT_PATH/LL/SpineML_2_BRAHMS_CL_neurons.xsl" &quot;$MODEL_DIR/<xsl:value-of select="$model_xml"/>&quot;
XSLTPROCRTN=$?
echo "xsltproc (for population component creation) returned: $XSLTPROCRTN"
if [ $XSLTPROCRTN -ne "0" ]; then
  echo "XSLT error generating population/neuron body component; exiting"
  exit $XSLTPROCRTN
fi
if [ ! -f "$SPINEML_CODE_DIR/component$CODE_NUM.cpp" ]; then
echo "Error: no component$CODE_NUM.cpp was generated by xsltproc from LL/SpineML_2_BRAHMS_CL_neurons.xsl and the model"
exit -1
fi
mkdir -p &quot;$DIRNAME&quot;
<!-- Copy rng.h and impulse.h -->
cp &quot;$MODEL_DIR/<xsl:value-of select="./SMLLOWNL:Neuron/@url"/>&quot; $SPINEML_2_BRAHMS_INCLUDE_PATH/rng.h $SPINEML_2_BRAHMS_INCLUDE_PATH/impulse.h &quot;$SPINEML_2_BRAHMS_NS/dev/SpineML/temp/NB/<xsl:value-of select="translate($linked_file/SMLCL:SpineML/SMLCL:ComponentClass/@name,' -', 'oH')"/>/brahms/0/&quot;
<!-- copy the component.cpp file -->
cp &quot;$SPINEML_CODE_DIR/component$CODE_NUM.cpp&quot; &quot;$SPINEML_2_BRAHMS_NS/dev/SpineML/temp/NB/<xsl:value-of select="translate($linked_file/SMLCL:SpineML/SMLCL:ComponentClass/@name,' -', 'oH')"/>/brahms/0/component.cpp&quot;
echo "&lt;Release&gt;&lt;Language&gt;1199&lt;/Language&gt;&lt;/Release&gt;" &amp;&gt; &quot;$SPINEML_2_BRAHMS_NS/dev/SpineML/temp/NB/<xsl:value-of select="translate($linked_file/SMLCL:SpineML/SMLCL:ComponentClass/@name,' -', 'oH')"/>/brahms/0/release.xml&quot;

echo 'g++ '$DBG_FLAG' <xsl:value-of select="$compiler_flags"/> component.cpp -o <xsl:value-of select="$component_output_file"/> -I`brahms --showinclude` -I`brahms --shownamespace` <xsl:value-of select="$platform_specific_includes"/> <xsl:value-of select="$linker_flags"/>' &amp;&gt; &quot;$SPINEML_2_BRAHMS_NS/dev/SpineML/temp/NB/<xsl:value-of select="translate($linked_file/SMLCL:SpineML/SMLCL:ComponentClass/@name,' -', 'oH')"/>/brahms/0/build&quot;

pushd &quot;$SPINEML_2_BRAHMS_NS/dev/SpineML/temp/NB/<xsl:value-of select="translate($linked_file/SMLCL:SpineML/SMLCL:ComponentClass/@name,' -', 'oH')"/>/brahms/0/&quot;
echo "&lt;Node&gt;&lt;Type&gt;Process&lt;/Type&gt;&lt;Specification&gt;&lt;Connectivity&gt;&lt;InputSets&gt;<xsl:for-each select="$linked_file/SMLCL:SpineML/SMLCL:ComponentClass/SMLCL:AnalogReducePort | $linked_file/SMLCL:SpineML/SMLCL:ComponentClass/SMLCL:EventReceivePort | $linked_file/SMLCL:SpineML/SMLCL:ComponentClass/SMLCL:ImpulseReceivePort">&lt;Set&gt;<xsl:value-of select="@name"/>&lt;/Set&gt;</xsl:for-each>&lt;/InputSets&gt;&lt;/Connectivity&gt;&lt;/Specification&gt;&lt;/Node&gt;" &amp;&gt; ../../node.xml
chmod +x build
echo "Compiling component binary"
./build
popd &amp;&gt; /dev/null
fi # The check if component code exists

</xsl:otherwise>
</xsl:choose>
</xsl:for-each>
fi # The enclosing check if the user wants to skip component existence checking



if [ x"${ASSUME_COMPONENTS_PRESENT}" = "x" ]; then
echo "Creating the projections..."
<xsl:for-each select="/SMLLOWNL:SpineML/SMLLOWNL:Population">
# Also update time.txt for SpineCreator / other tools
echo "*Compiling projections <xsl:value-of select="position()"/> / <xsl:value-of select="count(/SMLLOWNL:SpineML/SMLLOWNL:Population//SMLLOWNL:Projection)"/>" &gt; $MODEL_DIR/time.txt

<!-- Here we use the population number to determine which pop the projection belongs to -->
<xsl:variable name="number1"><xsl:number count="/SMLLOWNL:SpineML/SMLLOWNL:Population" format="1"/></xsl:variable>
	<xsl:variable name="src" select="@name"/>
	<xsl:for-each select=".//SMLLOWNL:Projection">
<!-- Here we use the Synapse number to determine which pop the projection targets -->
<xsl:variable name="number2"><xsl:number count="//SMLLOWNL:Projection" format="1"/></xsl:variable>
                <xsl:variable name="dest" select="@dst_population"/>
		<xsl:for-each select=".//SMLLOWNL:Synapse">
<!-- Here we use the target number to determine which WeightUpdate the projection targets -->
<xsl:variable name="number3"><xsl:number count="//SMLLOWNL:Synapse" format="1"/></xsl:variable>
echo "&lt;Nums&gt;&lt;Number1&gt;<xsl:value-of select="$number1"/>&lt;/Number1&gt;&lt;Number2&gt;<xsl:value-of select="$number2"/>&lt;/Number2&gt;&lt;Number3&gt;<xsl:value-of select="$number3"/>&lt;/Number3&gt;&lt;/Nums&gt;" &amp;&gt; "$SPINEML_RUN_DIR/counter.file"

<xsl:variable name="linked_file" select="document(SMLLOWNL:WeightUpdate/@url)"/>
<xsl:variable name="linked_file2" select="document(SMLLOWNL:PostSynapse/@url)"/>
<xsl:variable name="wu_url" select="SMLLOWNL:WeightUpdate/@url"/>
<xsl:variable name="ps_url" select="SMLLOWNL:PostSynapse/@url"/>

DIRNAME=&quot;$SPINEML_2_BRAHMS_NS/dev/SpineML/temp/WU/<xsl:value-of select="local-name(SMLNL:ConnectionList)"/><xsl:value-of select="local-name(SMLNL:FixedProbabilityConnection)"/><xsl:value-of select="local-name(SMLNL:AllToAllConnection)"/><xsl:value-of select="local-name(SMLNL:OneToOneConnection)"/><xsl:value-of select="translate(document(SMLLOWNL:WeightUpdate/@url)//SMLCL:ComponentClass/@name,' -', 'oH')"/>/brahms/0&quot;
CODE_NUM=$((CODE_NUM+1))
diff -q &quot;$MODEL_DIR/<xsl:value-of select="$wu_url"/>&quot; &quot;$DIRNAME/<xsl:value-of select="$wu_url"/>&quot; &amp;&gt; /dev/null
<!-- Check that the postsynapse component exists -->
if [ $? == 0 ] &amp;&amp; [ -f &quot;$DIRNAME/component.cpp&quot; ] &amp;&amp; [ -f &quot;$DIRNAME/<xsl:value-of select="$component_output_file"/>&quot; ]; then
<!-- The following echo will create a lot of output, but it's useful for debugging: -->
#echo "Weight Update component for population <xsl:value-of select="$number1"/>, projection <xsl:value-of select="$number2"/>, synapse <xsl:value-of select="$number3"/> exists, skipping ($DIRNAME/component.cpp)"
<!-- copy the component into our code folder -->
cp &quot;$DIRNAME/component.cpp&quot; &quot;$SPINEML_CODE_DIR/component$CODE_NUM.cpp&quot;
else
echo "Building weight update component.cpp for population <xsl:value-of select="$number1"/>, projection <xsl:value-of select="$number2"/>, synapse <xsl:value-of select="$number3"/> ($DIRNAME/component.cpp)"
<!-- output_dir passed to concat() and document() functions (as dir_for_numbers) in
     SpineML_2_BRAHMS_CL_weight.xsl so must be % encoded. -->
xsltproc -o "$SPINEML_CODE_DIR/component$CODE_NUM.cpp" --stringparam spineml_model_dir "$MODEL_DIR" --stringparam spineml_run_dir "$SPINEML_RUN_DIR_PERCENT_ENCODED" "$XSL_SCRIPT_PATH/LL/SpineML_2_BRAHMS_CL_weight.xsl" &quot;$MODEL_DIR/<xsl:value-of select="$model_xml"/>&quot;
XSLTPROCRTN=$?
echo "xsltproc (for weight update component creation) returned: $XSLTPROCRTN"
if [ $XSLTPROCRTN -ne "0" ]; then
  echo "XSLT error generating weight update component; exiting"
  exit $XSLTPROCRTN
fi
if [ ! -f "$SPINEML_CODE_DIR/component$CODE_NUM.cpp" ]; then
echo "Error: no component.cpp was generated by xsltproc from LL/SpineML_2_BRAHMS_CL_weight.xsl and the model"
exit -1
fi
mkdir -p "$DIRNAME"
cp &quot;$MODEL_DIR/<xsl:value-of select="$wu_url"/>&quot; $SPINEML_2_BRAHMS_INCLUDE_PATH/rng.h $SPINEML_2_BRAHMS_INCLUDE_PATH/impulse.h "$DIRNAME/"
cp "$SPINEML_CODE_DIR/component$CODE_NUM.cpp" "$DIRNAME/component.cpp"
echo "&lt;Release&gt;&lt;Language&gt;1199&lt;/Language&gt;&lt;/Release&gt;" &amp;&gt; "$DIRNAME/release.xml"

echo 'g++ '$DBG_FLAG' <xsl:value-of select="$compiler_flags"/> component.cpp -o <xsl:value-of select="$component_output_file"/> -I`brahms --showinclude` -I`brahms --shownamespace` <xsl:value-of select="$platform_specific_includes"/> <xsl:value-of select="$linker_flags"/>' &amp;&gt; "$DIRNAME/build"

cd "$DIRNAME"

echo "&lt;Node&gt;&lt;Type&gt;Process&lt;/Type&gt;&lt;Specification&gt;&lt;Connectivity&gt;&lt;InputSets&gt;<xsl:for-each select="$linked_file/SMLCL:SpineML/SMLCL:ComponentClass/SMLCL:AnalogReducePort | $linked_file/SMLCL:SpineML/SMLCL:ComponentClass/SMLCL:EventReceivePort | $linked_file/SMLCL:SpineML/SMLCL:ComponentClass/SMLCL:ImpulseReceivePort">&lt;Set&gt;<xsl:value-of select="@name"/>&lt;/Set&gt;</xsl:for-each>&lt;/InputSets&gt;&lt;/Connectivity&gt;&lt;/Specification&gt;&lt;/Node&gt;" &amp;&gt; ../../node.xml
chmod +x build
./build
cd - &amp;&gt; /dev/null
fi <!-- end check that the weight update component code exists -->

DIRNAME=&quot;$SPINEML_2_BRAHMS_NS/dev/SpineML/temp/PS/<xsl:for-each select="$linked_file2/SMLCL:SpineML/SMLCL:ComponentClass"><xsl:value-of select="translate(@name,' -', 'oH')"/></xsl:for-each>/brahms/0&quot;
CODE_NUM=$((CODE_NUM+1))
diff -q &quot;$MODEL_DIR/<xsl:value-of select="$ps_url"/>&quot; &quot;$DIRNAME/<xsl:value-of select="$ps_url"/>&quot; &amp;&gt; /dev/null
<!-- Check that the postsynapse component exists -->
if [ $? == 0 ] &amp;&amp; [ -f &quot;$DIRNAME/component.cpp&quot; ] &amp;&amp; [ -f &quot;$DIRNAME/<xsl:value-of select="$component_output_file"/>&quot; ]; then
<!-- Lots of output, but useful for debugging: -->
echo "Post-synapse component for population <xsl:value-of select="$number1"/>, projection <xsl:value-of select="$number2"/>, synapse <xsl:value-of select="$number3"/> exists, skipping ($DIRNAME/component.cpp)"
<!-- copy the component into our code folder -->
cp &quot;$DIRNAME/component.cpp&quot; &quot;$SPINEML_CODE_DIR/component$CODE_NUM.cpp&quot;
else
echo "Building postsynapse component.cpp for population <xsl:value-of select="$number1"/>, projection <xsl:value-of select="$number2"/>, synapse <xsl:value-of select="$number3"/> ($DIRNAME/component.cpp)"
<!-- output dir passed to document() in SpineML_2_BRAHMS_CL_postsyn.xsl; %-encoding required. -->
xsltproc -o "$SPINEML_CODE_DIR/component$CODE_NUM.cpp" --stringparam spineml_run_dir "$SPINEML_RUN_DIR_PERCENT_ENCODED" "$XSL_SCRIPT_PATH/LL/SpineML_2_BRAHMS_CL_postsyn.xsl" &quot;$MODEL_DIR/<xsl:value-of select="$model_xml"/>&quot;
XSLTPROCRTN=$?
echo "xsltproc (for postsynapse component creation) returned: $XSLTPROCRTN"
if [ $XSLTPROCRTN -ne "0" ]; then
  echo "XSLT error generating postsynapse component; exiting"
  exit $XSLTPROCRTN
fi
if [ ! -f "$SPINEML_CODE_DIR/component$CODE_NUM.cpp" ]; then
echo "Error: no component.cpp was generated by xsltproc from LL/SpineML_2_BRAHMS_CL_postsyn.xsl and the model"
exit -1
fi
mkdir -p "$DIRNAME"
cp &quot;$MODEL_DIR/<xsl:value-of select="$ps_url"/>&quot; $SPINEML_2_BRAHMS_INCLUDE_PATH/rng.h $SPINEML_2_BRAHMS_INCLUDE_PATH/impulse.h "$DIRNAME/"
cp "$SPINEML_CODE_DIR/component$CODE_NUM.cpp" "$DIRNAME/component.cpp"
echo "&lt;Release&gt;&lt;Language&gt;1199&lt;/Language&gt;&lt;/Release&gt;" &amp;&gt; "$DIRNAME/release.xml"

echo 'g++ '$DBG_FLAG' <xsl:value-of select="$compiler_flags"/> component.cpp -o <xsl:value-of select="$component_output_file"/> -I`brahms --showinclude` -I`brahms --shownamespace` <xsl:value-of select="$platform_specific_includes"/> <xsl:value-of select="$linker_flags"/>' &amp;&gt; "$DIRNAME/build"

cd "$DIRNAME"
echo "&lt;Node&gt;&lt;Type&gt;Process&lt;/Type&gt;&lt;Specification&gt;&lt;Connectivity&gt;&lt;InputSets&gt;<xsl:for-each select="$linked_file2/SMLCL:SpineML/SMLCL:ComponentClass/SMLCL:AnalogReducePort | $linked_file2/SMLCL:SpineML/SMLCL:ComponentClass/SMLCL:EventReceivePort | $linked_file2/SMLCL:SpineML/SMLCL:ComponentClass/SMLCL:ImpulseReceivePort">&lt;Set&gt;<xsl:value-of select="@name"/>&lt;/Set&gt;</xsl:for-each>&lt;/InputSets&gt;&lt;/Connectivity&gt;&lt;/Specification&gt;&lt;/Node&gt;" &amp;&gt; ../../node.xml
chmod +x build
./build
cd - &amp;&gt; /dev/null
fi <!-- end check that the postsynapse component exists -->
<!-- MORE HERE -->
</xsl:for-each>
</xsl:for-each>
</xsl:for-each>

fi <!-- end "assume" test -->

if [ "$REBUILD_SYSTEMML" = "true" ] || [ ! -f "$SPINEML_RUN_DIR/sys.xml" ] ; then
  echo "Building the SystemML system..."
  xsltproc -o "$SPINEML_RUN_DIR/sys.xml" --stringparam spineml_model_dir "$MODEL_DIR" "$XSL_SCRIPT_PATH/LL/SpineML_2_BRAHMS_NL.xsl" "$MODEL_DIR/$INPUT"
  XSLTPROCRTN=$?
  echo "xsltproc (for SystemML system) returned: $XSLTPROCRTN"
  if [ $XSLTPROCRTN -ne "0" ]; then
    echo "XSLT error generating SystemML system; exiting"
    exit $XSLTPROCRTN
  fi
else
  echo "Re-using the SystemML system."
fi

if [ "$REBUILD_SYSTEMML" = "true" ] || [ ! -f $SPINEML_RUN_DIR/sys-exe.xml ] ; then

echo "Building the SystemML execution..."

<!--
If in Sun Grid Engine mode and NODES is greater than 1, need to read all IP addresses
before building sys-exe.xml. Write the voices into a small xml file - brahms_voices.xml
- which will be used as input to xsltproc.
-->
if [[ "$NODES" -gt 1 ]]; then
  for (( NODE=1; NODE&lt;=$NODES; NODE++ )); do
    COUNTER="1"
    <!-- Note that we have a 120 second timeout for getting the node IP here - this
         is effectively the time that you have to wait for the SGE to start the job. -->
    SUN_GRID_ENGINE_TIMEOUT="120"
    echo "Waiting up to $SUN_GRID_ENGINE_TIMEOUT seconds for node $NODE to record its IP address..."
    while [ ! -f "$SPINEML_RUN_DIR/brahms_$NODE.ip" ] &amp;&amp; [ "$COUNTER" -lt "$SUN_GRID_ENGINE_TIMEOUT" ]; do
      sleep 1
      COUNTER=$((COUNTER+1))
    done
    if [ ! -f "$SPINEML_RUN_DIR/brahms_$NODE.ip" ]; then
      <!-- Still no IP, that's an error. -->
      echo "Error: Failed to learn IP address for brahms node $NODE, exiting."
      exit -1
    fi <!-- else we have the IP, so can read it to send it into the xsltproc call. -->
  done

  echo -n "&lt;Voices&gt;" &gt; "$SPINEML_RUN_DIR/brahms_voices.xml"
  for (( NODE=1; NODE&lt;=$NODES; NODE++ )); do
    read NODEIP &lt; "$SPINEML_RUN_DIR/brahms_$NODE.ip"
    echo -n "&lt;Voice&gt;&lt;Address protocol=\&quot;sockets\&quot;&gt;$NODEIP&lt;/Address&gt;&lt;/Voice&gt;" &gt;&gt; "$SPINEML_RUN_DIR/brahms_voices.xml"
  done
  echo -n "&lt;/Voices&gt;" &gt;&gt; "$SPINEML_RUN_DIR/brahms_voices.xml"
else
  echo "&lt;Voices&gt;&lt;Voice/&gt;&lt;/Voices&gt;" &gt; "$SPINEML_RUN_DIR/brahms_voices.xml"
fi

<!-- SPINEML_RUN_DIR/voices_file passed to document() function in SpineML_2_BRAHMS_EXPT.xsl; must be %-encoded. -->
xsltproc -o "$SPINEML_RUN_DIR/sys-exe.xml" --stringparam voices_file "$SPINEML_RUN_DIR_PERCENT_ENCODED/brahms_voices.xml" "$XSL_SCRIPT_PATH/LL/SpineML_2_BRAHMS_EXPT.xsl" "$MODEL_DIR/$INPUT"
XSLTPROCRTN=$?
echo "xsltproc (for sys-exe.xml) returned: $XSLTPROCRTN"
if [ $XSLTPROCRTN -ne "0" ]; then
  echo "XSLT error generating sys-exe.xml; exiting"
  exit $XSLTPROCRTN
fi

else
  echo "Re-using the SystemML execution."
fi

echo "Done!"

<!-- If not in Sun Grid Engine mode, run! -->
if [[ "$NODES" -eq 0 ]]; then
  cd "$SPINEML_RUN_DIR"
  echo -n "Executing: $BRAHMS_CMD from pwd: "
  echo `pwd`
  eval $BRAHMS_CMD
else
  echo "Simulation has been submitted to Sun Grid Engine."
fi
</xsl:when>
<!-- END SMLLOWNL SECTION -->
<!-- SpineML high level network layer -->
<!-- FIXME: Need to reproduce the script above for SMLLOWNL here, with SMLLOWNL replaced by SMLNL: -->
<xsl:when test="SMLNL:SpineML">#/bin/bash
echo "Duplicate code for the SMLLOWNL case from START SMLLOWNL SECTION to END SMLLOWNL SECTION."
exit 1
</xsl:when>
<xsl:otherwise>
echo "ERROR: Unrecognised SpineML Network Layer file";
</xsl:otherwise>
</xsl:choose>
</xsl:for-each>
</xsl:template>

</xsl:stylesheet>
