<?xml version="1.0" encoding="ISO-8859-1"?><xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:SMLLOWNL="http://www.shef.ac.uk/SpineMLLowLevelNetworkLayer" xmlns:SMLNL="http://www.shef.ac.uk/SpineMLNetworkLayer" xmlns:SMLCL="http://www.shef.ac.uk/SpineMLComponentLayer" xmlns:fn="http://www.w3.org/2005/xpath-functions">
<xsl:output method="text" version="1.0" encoding="UTF-8" indent="yes"/>

<xsl:param name="spineml_model_dir" select="'not_used'"/>
<xsl:param name="spineml_run_dir" select="'not_used'"/>

<xsl:include href="SpineML_helpers.xsl"/>

<xsl:template match="/">
<xsl:for-each select="//SMLLOWNL:Synapse">
<xsl:variable name="process_name"><xsl:value-of select="local-name(SMLNL:ConnectionList)"/><xsl:value-of select="local-name(SMLNL:FixedProbabilityConnection)"/><xsl:value-of select="local-name(SMLNL:AllToAllConnection)"/><xsl:value-of select="local-name(SMLNL:OneToOneConnection)"/><xsl:value-of select="translate(document(SMLLOWNL:WeightUpdate/@url)//SMLCL:ComponentClass/@name,' -', 'oH')"/></xsl:variable>
<!--xsl:variable name="rule_proto" select="@prototype"/>
<xsl:variable name="rule_file" select="document(/SMLLOWNL:SpineML/SMLNL:Node[@name=$rule_proto]/@url)"/-->
<xsl:variable name="WeightUpdate_file" select="document(SMLLOWNL:WeightUpdate/@url)"/>
<!-- Here we use the numbers to determine what we are outputting -->
<xsl:variable name="number1"><xsl:number count="//SMLLOWNL:Population" format="1"/></xsl:variable>
<xsl:variable name="number2"><xsl:number count="//SMLLOWNL:Projection" format="1"/></xsl:variable>
<xsl:variable name="dir_for_numbers"> <!-- from output dir -->
	<xsl:if test="$spineml_run_dir='not_used'">../../temp</xsl:if>
	<xsl:if test="not($spineml_run_dir='not_used')"><xsl:value-of select="$spineml_run_dir"/></xsl:if>
</xsl:variable>
<xsl:variable name="number3"><xsl:number count="//SMLLOWNL:Synapse" format="1"/></xsl:variable>
<xsl:if test="$number1 = number(document(concat($dir_for_numbers,'/counter.file'))/Nums/Number1) and $number2 = number(document(concat($dir_for_numbers,'/counter.file'))/Nums/Number2) and $number3 = number(document(concat($dir_for_numbers,'/counter.file'))/Nums/Number3)">

<xsl:variable name="dstPopName" select="../../@dst_population"/>
<xsl:variable name="dstPop" select="//SMLLOWNL:Population[SMLLOWNL:Neuron/@name=$dstPopName]"/>

/*
   Autogenerated BRAHMS process from SpineML description.
   Engine: XSLT
   Engine Author: Alex Cope 2012
   Node name: <xsl:value-of select="$process_name"/>
*/

#define COMPONENT_CLASS_STRING "dev/SpineML/temp/WU/<xsl:value-of select="$process_name"/>"
#define COMPONENT_CLASS_CPP dev_spineml_wu_<xsl:value-of select="$process_name"/>_0
#define COMPONENT_RELEASE 0
#define COMPONENT_REVISION 1
#define COMPONENT_ADDITIONAL "Author=SpineML_2_BRAHMS\n" "URL=Not supplied\n"
#define COMPONENT_FLAGS (F_NOT_RATE_CHANGER)

#define OVERLAY_QUICKSTART_PROCESS

//	include the component interface overlay (component bindings 1199)
#include "brahms-1199.h"

//	alias data and util namespaces to something briefer
namespace numeric = std_2009_data_numeric_0;
namespace spikes = std_2009_data_spikes_0;
namespace rng = std_2009_util_rng_0;

using namespace std;

#include "rng.h"
// Some very SpineML_2_BRAHMS specific defines, common to all components.
#define randomUniform     _randomUniform(&amp;this-&gt;rngData_BRAHMS)
#define randomNormal      _randomNormal(&amp;this-&gt;rngData_BRAHMS)
#define randomExponential _randomExponential(&amp;this-&gt;rngData_BRAHMS)
#define randomPoisson     _randomPoisson(&amp;this-&gt;rngData_BRAHMS)
#include "impulse.h"

// structure allowing weights to be sent with spikes
struct INT32SINGLE {
	INT32 i;
	SINGLE s;
};

float dt;

class COMPONENT_CLASS_CPP;

<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass/SMLCL:Dynamics">
	<xsl:apply-templates select="SMLCL:Regime" mode="defineTimeDerivFuncsPtr1"/>
</xsl:for-each>

////////////////	COMPONENT CLASS (DERIVES FROM Process)

class COMPONENT_CLASS_CPP : public Process
{
public:
	//	use ctor/dtor only if required
	COMPONENT_CLASS_CPP() {}
	~COMPONENT_CLASS_CPP() {}

	//	the framework event function
	Symbol event(Event* event);

private:
	// Some data for the random number generator.
	RngData rngData_BRAHMS;

	float t;

	// base name
	string baseNameForLogs_BRAHMS;

	// model directory string
	string modelDirectory_BRAHMS;

	// define regimes
	<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass/SMLCL:Dynamics">
		<xsl:apply-templates select="SMLCL:Regime" mode="defineRegime"/>
	</xsl:for-each>


	// Global variables
	vector &lt; int &gt; <xsl:value-of select="concat(translate($WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass/@name,' -', '_H'), 'O__O')"/>regime;
	vector &lt; int &gt; <xsl:value-of select="concat(translate($WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass/@name,' -', '_H'), 'O__O')"/>regimeNext;


	VDOUBLE size_BRAHMS;
	int numConn_BRAHMS;
	int numElements_BRAHMS;
	int numElementsIn_BRAHMS;

	VUINT32 delayForConn;

	vector &lt; VINT32 &gt; delayBuffer;
	vector &lt; VDOUBLE &gt; delayedAnalogVals;

	int delayBufferIndex;

	// create the lookups for the connectivity
	vector &lt; vector &lt; int &gt; &gt; connectivityS2C;
	vector &lt; vector &lt; int &gt; &gt; connectivityD2C;
	vector &lt; int &gt; connectivityC2S;
	vector &lt; int &gt; connectivityC2D;

	// Analog Ports
	<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass">
	<xsl:apply-templates select="SMLCL:AnalogReceivePort | SMLCL:AnalogSendPort | SMLCL:AnalogReducePort" mode="defineAnalogPorts"/>
	</xsl:for-each>

	// Event Ports
	<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass">
	<xsl:apply-templates select="SMLCL:EventReceivePort | SMLCL:EventSendPort" mode="defineEventPorts"/>
	</xsl:for-each>

	// Impulse Ports
	<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass">
		<xsl:apply-templates select="SMLCL:ImpulseReceivePort | SMLCL:ImpulseSendPort" mode="defineImpulsePorts"/>
	</xsl:for-each>

	// State Variables
	<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass/SMLCL:Dynamics">
		<xsl:apply-templates select="SMLCL:StateVariable" mode="defineStateVariable"/>
	</xsl:for-each>

	// Parameters
	<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass">
		<xsl:apply-templates select="SMLCL:Parameter" mode="defineParameter"/>
	</xsl:for-each>

	// Add aliases that are not inputs
	<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass//SMLCL:Alias">
		<xsl:variable name="aliasName" select="@name"/>
		<xsl:if test="count(//SMLCL:AnalogSendPort[@name=$aliasName])=0">
			<xsl:apply-templates select="." mode="defineAlias"/>
		</xsl:if>
	</xsl:for-each>

	<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass/SMLCL:Dynamics">
		<xsl:apply-templates select="SMLCL:Regime" mode="defineTimeDerivFuncs"/>
	</xsl:for-each>

	float integrate(float x, float (COMPONENT_CLASS_CPP::*func)(float, int), int num)
	{
		return x + (*this.*func)(x,num)*dt;
	}

#ifdef RUNGE_KUTTA
	// Runge Kutta 4th order
	float integrate(float x, float (COMPONENT_CLASS_CPP::*func)(float, int), int num)
	{
		float k1 = dt*(*this.*func)(x,num);
		float k2 = dt*(*this.*func)(x+0.5*k1,num);
		float k3 = dt*(*this.*func)(x+0.5*k2,num);
		float k4 = dt*(*this.*func)(x+k3,num);
		return x + (1.0/6.0)*(k1 + 2.0*k2 + 2.0*k3 + k4);
	}
#endif
};

////////////////	EVENT

Symbol COMPONENT_CLASS_CPP::event(Event* event)
{
	switch(event->type)
	{
		case EVENT_STATE_SET:
		{
			//	extract DataML
			EventStateSet* data = (EventStateSet*) event->data;
			XMLNode xmlNode(data->state);
			DataMLNode nodeState(&amp;xmlNode);

			// obtain the parameters
			size_BRAHMS = nodeState.getField("sizeIn").getArrayDOUBLE();
			numElementsIn_BRAHMS = 1;
			for (int i_BRAHMS = 0; i_BRAHMS &lt; size_BRAHMS.size(); ++i_BRAHMS) {
				numElementsIn_BRAHMS *= size_BRAHMS[i_BRAHMS];
			}

			size_BRAHMS = nodeState.getField("sizeOut").getArrayDOUBLE();
			numElements_BRAHMS = 1;
			for (int i_BRAHMS = 0; i_BRAHMS &lt; size_BRAHMS.size(); ++i_BRAHMS) {
				numElements_BRAHMS *= size_BRAHMS[i_BRAHMS];
			}

			// Ensure field is present (trigger BRAHMS error if not)
			modelDirectory_BRAHMS = nodeState.getField("model_directory").getSTRING();

			rngDataInit(&amp;this-&gt;rngData_BRAHMS);
			zigset(&amp;this-&gt;rngData_BRAHMS, 11);

			// Create the connectivity map
                        <xsl:if test="count(./SMLNL:AllToAllConnection) = 1">
			connectivityC2D.reserve(numElementsIn_BRAHMS*numElements_BRAHMS);
			connectivityS2C.resize(numElementsIn_BRAHMS);
			for (UINT32 i_BRAHMS = 0; i_BRAHMS &lt; connectivityS2C.size(); ++i_BRAHMS) {
				connectivityS2C[i_BRAHMS].resize(numElements_BRAHMS);
				for (unsigned int j_BRAHMS = 0; j_BRAHMS &lt; connectivityS2C[i_BRAHMS].size(); ++j_BRAHMS) {
					connectivityC2D.push_back(j_BRAHMS);
					connectivityS2C[i_BRAHMS][j_BRAHMS] = connectivityC2D.size()-1;

				}
			}

			// set up the number of connections
			numConn_BRAHMS = connectivityC2D.size();
			</xsl:if>
                        <xsl:if test="count(./SMLNL:OneToOneConnection) = 1">
			connectivityC2D.resize(numElementsIn_BRAHMS);
			connectivityS2C.resize(numElementsIn_BRAHMS);
			for (UINT32 i_BRAHMS = 0; i_BRAHMS &lt; connectivityS2C.size(); ++i_BRAHMS) {
				connectivityS2C[i_BRAHMS].push_back(i_BRAHMS);
			}
			for (UINT32 i_BRAHMS = 0; i_BRAHMS &lt; connectivityC2D.size(); ++i_BRAHMS) {
				connectivityC2D[i_BRAHMS] = i_BRAHMS;
			}

			// set up the number of connections
			numConn_BRAHMS = connectivityC2D.size();
			</xsl:if>

			<xsl:if test="count(./SMLNL:FixedProbabilityConnection) = 1">
			// get the probability
			float probabilityValue_BRAHMS = nodeState.getField("probabilityValue").getDOUBLE();
			// seed the rng:
			zigset(&amp;this-&gt;rngData_BRAHMS, 1<xsl:value-of select=".//SMLNL:FixedProbabilityConnection/@seed"/>);
			this-&gt;rngData_BRAHMS.seed = 123;
			// run through connections, creating connectivity pattern:
			connectivityC2D.reserve(numElements_BRAHMS);
			connectivityS2C.resize(numElementsIn_BRAHMS);
			for (UINT32 i_BRAHMS = 0; i_BRAHMS &lt; connectivityS2C.size(); ++i_BRAHMS) {
				connectivityS2C[i_BRAHMS].reserve((int) round(numElements_BRAHMS*probabilityValue_BRAHMS));
			}
			for (UINT32 srcIndex_BRAHMS = 0; srcIndex_BRAHMS &lt; numElementsIn_BRAHMS; ++srcIndex_BRAHMS) {
				for (UINT32 dstIndex_BRAHMS = 0; dstIndex_BRAHMS &lt; numElements_BRAHMS; ++dstIndex_BRAHMS) {
					if (UNI(&amp;this-&gt;rngData_BRAHMS) &lt; probabilityValue_BRAHMS) {
						connectivityC2D.push_back(dstIndex_BRAHMS);
						connectivityS2C[srcIndex_BRAHMS].push_back(connectivityC2D.size()-1);
					}

				}
				if (float(connectivityC2D.size()) > 0.9*float(connectivityC2D.capacity())) {
					connectivityC2D.reserve(connectivityC2D.capacity()+numElements_BRAHMS);
				}
			}

			// set up the number of connections
			numConn_BRAHMS = connectivityC2D.size();
			//bout &lt;&lt; float(numConn_BRAHMS) &lt;&lt; D_INFO;
			</xsl:if>

			VDOUBLE delayForConnTemp;

			<xsl:if test="./SMLNL:ConnectionList">
			vector &lt;INT32&gt; srcInds;
			vector &lt;INT32&gt; dstInds;
			if (nodeState.hasField("_bin_file_name")) {
				string fileName = nodeState.getField("_bin_file_name").getSTRING();
				int _num_conn = (int) nodeState.getField("_bin_num_conn").getDOUBLE();
				bool _has_delay = (bool) nodeState.getField("_bin_has_delay").getDOUBLE();

				// open the file for reading
				FILE * binfile;

				fileName = modelDirectory_BRAHMS + "/" + fileName;
				binfile = fopen(fileName.c_str(),"rb");

				if (!binfile) {
					berr &lt;&lt; "Could not open connectivity file: " &lt;&lt; fileName;
				}

				srcInds.resize(_num_conn);
				dstInds.resize(_num_conn);
				if (_has_delay) {
					delayForConnTemp.resize(_num_conn);
				}
				for (int i_BRAHMS = 0; i_BRAHMS &lt; _num_conn; ++i_BRAHMS) {
					size_t ret_FOR_BRAHMS = fread(&amp;srcInds[i_BRAHMS], sizeof(unsigned int), 1, binfile);
					if (ret_FOR_BRAHMS == -1) { berr &lt;&lt; "Error loading binary connections"; }
					ret_FOR_BRAHMS = fread(&amp;dstInds[i_BRAHMS], sizeof(unsigned int), 1, binfile);
					if (ret_FOR_BRAHMS == -1) { berr &lt;&lt; "Error loading binary connections"; }
					if (_has_delay) {
						float tempDelay_FOR_BRAHMS;
						ret_FOR_BRAHMS = fread(&amp;tempDelay_FOR_BRAHMS, sizeof(float), 1, binfile);
						delayForConnTemp[i_BRAHMS] = tempDelay_FOR_BRAHMS;
					}
					if (ret_FOR_BRAHMS == -1) berr &lt;&lt; "Error loading binary connections";
					//bout  &lt;&lt; srcInds[i_BRAHMS] &lt;&lt; " " &lt;&lt; dstInds[i_BRAHMS] &lt;&lt; " " &lt;&lt; delayForConnTemp[i_BRAHMS] &lt;&lt; D_WARN;
				}
			} else {
				srcInds = nodeState.getField("src").getArrayINT32();
				dstInds = nodeState.getField("dst").getArrayINT32();

				if (srcInds.size() != dstInds.size()) {
					berr &lt;&lt; "Connectivity src and dst lists have different sizes";
				}
			}

			numConn_BRAHMS = srcInds.size();

			// sanity check on index values
			for (unsigned int i_BRAHMS = 0; i_BRAHMS &lt; srcInds.size(); ++i_BRAHMS) {
				if (srcInds[i_BRAHMS] >= numElementsIn_BRAHMS || dstInds[i_BRAHMS] >= numElements_BRAHMS) {
					berr &lt;&lt; "src index (" &lt;&lt; srcInds[i_BRAHMS]
					     &lt;&lt;") or dst index (" &lt;&lt; dstInds[i_BRAHMS]
					     &lt;&lt;") out of range (" &lt;&lt; numElements_BRAHMS &lt;&lt;")";
				}
			}

			// assign the connectivity pattern into memory
			connectivityS2C.resize(numElementsIn_BRAHMS);
			connectivityC2D.resize(srcInds.size());
			for (int i_BRAHMS = 0; i_BRAHMS &lt; srcInds.size(); ++i_BRAHMS) {
				connectivityS2C[srcInds[i_BRAHMS]].push_back(i_BRAHMS);
				connectivityC2D[i_BRAHMS] = dstInds[i_BRAHMS];
			}
			</xsl:if>

			// get delay
			if (nodeState.hasField("delayForConn")) {
				delayForConnTemp = nodeState.getField("delayForConn").getArrayDOUBLE();
			}

			delayBufferIndex = 0;

			if (delayForConnTemp.size() > 0) {

				if (delayForConnTemp.size() != numConn_BRAHMS) berr &lt;&lt; "Connectivity delay list has incorrect size";

				// resize buffer
				float max_delay_val = 0;
				float most_delay_accuracy = (1000.0f * time->sampleRate.den / time->sampleRate.num);
				for (UINT32 i_BRAHMS = 0; i_BRAHMS &lt; delayForConnTemp.size(); ++i_BRAHMS) {
					delayForConnTemp[i_BRAHMS];
					if (delayForConnTemp[i_BRAHMS] > max_delay_val) max_delay_val = delayForConnTemp[i_BRAHMS];
				}

				delayBuffer.resize(round(max_delay_val/most_delay_accuracy)+1);
				delayedAnalogVals.resize(round(max_delay_val/most_delay_accuracy)+1);

				// remap the delays to indices
				delayForConn.resize(delayForConnTemp.size());

				//delayBufferIndexCounter = 0;
				//delayBufferIndexCounterMax = round(most_delay_accuracy/(1000.0f * time->sampleRate.den / time->sampleRate.num));

				//bout&lt;&lt; most_delay_accuracy &lt;&lt; D_INFO;
				//bout&lt;&lt; float(delayBuffer.size()) &lt;&lt; D_INFO;
				for (UINT32 i_BRAHMS = 0; i_BRAHMS &lt; delayForConnTemp.size(); ++i_BRAHMS) {
					delayForConn[i_BRAHMS] = round(delayForConnTemp[i_BRAHMS]/most_delay_accuracy);
					//&lt;&lt;delayForConn[i_BRAHMS] &lt;&lt; D_INFO;
				}
			}

			// check for probabilistic delay
			if (nodeState.hasField("pDelay")) {
				delayForConnTemp = nodeState.getField("pDelay").getArrayDOUBLE();
				bout &lt;&lt; "have p delays" &lt;&lt; D_INFO;
			}

			// check what is happening
			if (delayForConnTemp.size() == 4) {

				bout &lt;&lt; "have p delays: right size" &lt;&lt; D_INFO;

				// resize the buffer
				delayForConn.resize(numConn_BRAHMS);

				float max_delay_val = 0;
				float most_delay_accuracy = (1000.0f * time->sampleRate.den / time->sampleRate.num);

				// generate the delays:
				if (delayForConnTemp[0] == 1) { // Normal distribution
					this-&gt;rngData_BRAHMS.seed = delayForConnTemp[3];
					for (UINT32 i_BRAHMS = 0; i_BRAHMS &lt; delayForConn.size(); ++i_BRAHMS) {
						delayForConn[i_BRAHMS] = round((RNOR(&amp;this-&gt;rngData_BRAHMS)*delayForConnTemp[2]+delayForConnTemp[1])/most_delay_accuracy);
						//bout &lt;&lt;delayForConn[i_BRAHMS] &lt;&lt; D_INFO;
						if (delayForConn[i_BRAHMS] &lt; 0) delayForConn[i_BRAHMS] = 0;
						if (delayForConn[i_BRAHMS] &gt; max_delay_val) max_delay_val = delayForConn[i_BRAHMS];
					}
				}
				if (delayForConnTemp[0] == 2) { // Uniform distribution
					this-&gt;rngData_BRAHMS.seed = delayForConnTemp[3];
					for (UINT32 i_BRAHMS = 0; i_BRAHMS &lt; delayForConn.size(); ++i_BRAHMS) {
						delayForConn[i_BRAHMS] = round((_randomUniform(&amp;this-&gt;rngData_BRAHMS)*(delayForConnTemp[2]-delayForConnTemp[1])+delayForConnTemp[1])/most_delay_accuracy);
						//bout &lt;&lt;delayForConn[i_BRAHMS] &lt;&lt; D_INFO;
						if (delayForConn[i_BRAHMS] &gt; max_delay_val) { max_delay_val = delayForConn[i_BRAHMS]; }
					}
				}

				bout &lt;&lt; (round(max_delay_val/most_delay_accuracy)+1) &lt;&lt; " = moo" &lt;&lt; D_INFO;

				delayBuffer.resize(round(max_delay_val/most_delay_accuracy)+1);
				delayedAnalogVals.resize(round(max_delay_val/most_delay_accuracy)+1);
			}

			//debug
			//bout &lt;&lt; float(numConn_BRAHMS) &lt;&lt; D_INFO;

			int numEl_BRAHMS = numConn_BRAHMS;

			// State Variables
<!---->
			<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass/SMLCL:Dynamics">
				<xsl:apply-templates select="SMLCL:StateVariable" mode="assignStateVariable"/>
			</xsl:for-each>

			// Parameters
<!---->
			<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass">
				<xsl:apply-templates select="SMLCL:Parameter" mode="assignParameter"/>
			</xsl:for-each>

			// Alias resize
<!---->
			<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass/SMLCL:Dynamics">
				<xsl:apply-templates select="SMLCL:Alias" mode="resizeAlias"/>
			</xsl:for-each>

			// Log base name
			baseNameForLogs_BRAHMS = "../log/" + nodeState.getField("logfileNameForComponent").getSTRING();
			<!-- State variable names -->
			<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass/SMLCL:Dynamics/SMLCL:StateVariable">
				<xsl:value-of select="@name"/>_BINARY_FILE_NAME_OUT = "../model/" + nodeState.getField("<xsl:value-of select="@name"/>BIN_FILE_NAME").getSTRING();
			</xsl:for-each>



			// Logs
			<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass">
				<xsl:apply-templates select="SMLCL:AnalogSendPort | SMLCL:EventSendPort" mode="createSendPortLogs"/>
			</xsl:for-each>

			<xsl:text>
			</xsl:text>
			<!-- SELECT INITIAL_REGIME, OR DEFAULT TO REGIME 1 -->
			<xsl:value-of select="concat(translate($WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass/@name,' -', '_H'), 'O__O')"/>regime.resize(numEl_BRAHMS,<!---->
			<xsl:if test="$WeightUpdate_file//SMLCL:Dynamics/@initial_regime">
				<xsl:for-each select="$WeightUpdate_file//SMLCL:Regime">
					<xsl:if test="$WeightUpdate_file//SMLCL:Dynamics/@initial_regime=@name">
						<xsl:value-of select="position()"/>
					</xsl:if>
				</xsl:for-each>
			</xsl:if>
			<xsl:if test="count($WeightUpdate_file//SMLCL:Dynamics/@initial_regime)=0">1</xsl:if>);
			<xsl:value-of select="concat(translate($WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass/@name,' -', '_H'), 'O__O')"/>regimeNext.resize(numEl_BRAHMS,0);

			dt = 1000.0f * time->sampleRate.den / time->sampleRate.num;
<!---->
			<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass/SMLCL:Dynamics">
				<xsl:apply-templates select="SMLCL:Regime" mode="defineTimeDerivFuncsPtr"/>
			</xsl:for-each>
<!---->
			<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass">
				<xsl:apply-templates select="SMLCL:ImpulseReceivePort" mode="resizeReceive"/>
			</xsl:for-each>
		}

		// CREATE THE PORTS
		case EVENT_INIT_CONNECT:
		{
			Dims sizeDims_BRAHMS;
			for (int i_BRAHMS = 0; i_BRAHMS &lt; size_BRAHMS.size(); ++i_BRAHMS) {
				sizeDims_BRAHMS.push_back(size_BRAHMS[i_BRAHMS]);
			}
			//	on first call
			if (event->flags &amp; F_FIRST_CALL) {
				// create output ports
<!---->
				<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass">
					<xsl:apply-templates select="SMLCL:AnalogSendPort" mode="createAnalogSendPorts"/>
				</xsl:for-each>

				<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass">
					<xsl:apply-templates select="SMLCL:ImpulseSendPort" mode="createImpulseSendPortsWU"/>
				</xsl:for-each>

				<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass">
					<xsl:apply-templates select="SMLCL:EventSendPort" mode="createEventSendPorts"/>
				</xsl:for-each>
<!---->
			}

			// on last call
			if (event->flags &amp; F_LAST_CALL) {
				int numInputs_BRAHMS;
				Symbol set_BRAHMS;

				// create input ports
<!---->
				<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass">
					<xsl:apply-templates select="SMLCL:AnalogReceivePort" mode="createAnalogRecvPorts"/>
				</xsl:for-each>

				<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass">
					<xsl:apply-templates select="SMLCL:AnalogReducePort" mode="createAnalogReducePortsRemap"/>
				</xsl:for-each>

				<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass">
					<xsl:apply-templates select="SMLCL:ImpulseReceivePort" mode="createImpulseRecvPorts"/>
				</xsl:for-each>

				<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass">
					<xsl:apply-templates select="SMLCL:EventReceivePort" mode="createEventRecvPorts"/>
				</xsl:for-each>
<!---->
			}

			// re-seed
			this-&gt;rngData_BRAHMS.seed = getTime();

			return C_OK;
		}

		case EVENT_RUN_SERVICE:
		{
			t = float(time->now)*dt;

			int num_BRAHMS;
			int numEl_BRAHMS = numConn_BRAHMS;

			// move delayBufferIndex
			if (delayBuffer.size()) {
				++delayBufferIndex;
				delayBufferIndex = delayBufferIndex%delayBuffer.size();
			}

			for (int i_BRAHMS = 0; i_BRAHMS &lt; <xsl:value-of select="concat(translate($WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass/@name,' -', '_H'), 'O__O')"/>regime.size(); ++i_BRAHMS) {

			    <xsl:value-of select="concat(translate($WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass/@name,' -', '_H'), 'O__O')"/>regimeNext[i_BRAHMS] = <xsl:value-of select="concat(translate($WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass/@name,' -', '_H'), 'O__O')"/>regime[i_BRAHMS];

			}

			// service inputs
<!---->
			<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass">
				<xsl:apply-templates select="SMLCL:AnalogReceivePort | SMLCL:AnalogReducePort" mode="serviceAnalogPortsRemap"/>
			</xsl:for-each>

			<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass">
				<xsl:apply-templates select="SMLCL:ImpulseReceivePort | SMLCL:ImpulseSendPort" mode="serviceImpulsePortsRemap"/>
			</xsl:for-each>

			<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass">
				<xsl:apply-templates select="SMLCL:EventReceivePort | SMLCL:EventSendPort" mode="serviceEventPortsRemap"/>
			</xsl:for-each>

			<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass">
				<xsl:apply-templates select="SMLCL:Dynamics" mode="doEventInputsRemap"/>
			</xsl:for-each>

			<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass">
				<xsl:apply-templates select="SMLCL:Dynamics" mode="doImpulseInputsRemap"/>
			</xsl:for-each>

			<!-- REMAPPED -->

			<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass">
				<xsl:apply-templates select="SMLCL:Dynamics" mode="doIter"/>
			</xsl:for-each>

			<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass">
				<xsl:apply-templates select="SMLCL:Dynamics" mode="doTrans"/>
			</xsl:for-each>
<!---->

			// Apply regime changes
			for (int i_BRAHMS = 0; i_BRAHMS &lt; <xsl:value-of select="concat(translate($WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass/@name,' -', '_H'), 'O__O')"/>regime.size(); ++i_BRAHMS) {
						        <xsl:value-of select="concat(translate($WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass/@name,' -', '_H'), 'O__O')"/>regime[i_BRAHMS] = <xsl:value-of select="concat(translate($WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass/@name,' -', '_H'), 'O__O')"/>regimeNext[i_BRAHMS];

			// updating logs...
           		<xsl:apply-templates select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass/SMLCL:AnalogSendPort" mode="makeSendPortLogs"/>
			}

			// updating logs...
			<xsl:apply-templates select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass/SMLCL:EventSendPort" mode="makeSendPortLogs"/>

           		// writing logs...
			<xsl:apply-templates select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass/SMLCL:AnalogSendPort" mode="saveSendPortLogs"/>

<!---->
			<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass">
				<xsl:apply-templates select="SMLCL:AnalogReceivePort | SMLCL:AnalogSendPort | SMLCL:AnalogReducePort" mode="outputAnalogPortsRemap"/>
			</xsl:for-each>

			<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass">
				<xsl:apply-templates select="SMLCL:EventReceivePort | SMLCL:EventSendPort" mode="outputEventPortsRemap"/>
			</xsl:for-each>

			<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass">
				<xsl:apply-templates select="SMLCL:ImpulseReceivePort | SMLCL:ImpulseSendPort" mode="outputImpulsePortsRemap"/>
			</xsl:for-each>

			//bout &lt;&lt; " " &lt;&lt; OUTPSP[2] &lt;&lt; " " &lt;&lt; out[0] &lt;&lt; " " &lt;&lt; w[0] &lt;&lt; D_INFO;

			return C_OK;
		}

		case EVENT_RUN_STOP:
		{
			int numEl_BRAHMS = numConn_BRAHMS;
			t = float(time->now)*dt;

			<!-- WRITE XML FOR LOGS -->
			<xsl:apply-templates select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass/SMLCL:EventSendPort | $WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass/SMLCL:AnalogSendPort" mode="finaliseLogs"/>

			<!-- Write out state variables -->
			<xsl:for-each select="$WeightUpdate_file/SMLCL:SpineML/SMLCL:ComponentClass/SMLCL:Dynamics">
				<xsl:apply-templates select="SMLCL:StateVariable" mode="writeoutStateVariable"/>
			</xsl:for-each>
			return C_OK;
		}
	}

	// return S_NULL to indicate event was not serviced.
	return S_NULL;
}







//	include the second part of the overlay (it knows you've included it once already)
#include "brahms-1199.h"


</xsl:if>


</xsl:for-each>


</xsl:template>

<xsl:include href="SpineML_Dynamics.xsl"/>
<xsl:include href="SpineML_Regime.xsl"/>
<xsl:include href="SpineML_StateVariable.xsl"/>
<xsl:include href="SpineML_Parameter.xsl"/>
<xsl:include href="SpineML_AnalogPort.xsl"/>
<xsl:include href="SpineML_EventPort.xsl"/>
<xsl:include href="SpineML_ImpulsePort.xsl"/>

</xsl:stylesheet>


