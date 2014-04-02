

/*
   Autogenerated BRAHMS process from 9ML description.
   Engine: XSLT
   Engine Author: Alex Cope 2012
   Node name: 
*/


#define COMPONENT_CLASS_STRING "dev/SpineML/tools/explicitList"
#define COMPONENT_CLASS_CPP dev_spineml_tools_explicitlist_0
#define COMPONENT_RELEASE 0
#define COMPONENT_REVISION 1
#define COMPONENT_ADDITIONAL "Author=NineML_2_BRAHMS\n" "URL=Not supplied\n"
#define COMPONENT_FLAGS (F_NOT_RATE_CHANGER)

#define OVERLAY_QUICKSTART_PROCESS

//	include the component interface overlay (component bindings 1199)
#include "brahms-1199.h"


//	alias data and util namespaces to something briefer
namespace numeric = std_2009_data_numeric_0;
namespace spikes = std_2009_data_spikes_0;
namespace rng = std_2009_util_rng_0;

using namespace std;

#include "impulse.h"

class COMPONENT_CLASS_CPP;



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





// Analog Ports

numeric::Input in;

numeric::Output out;

spikes::Input ins;

spikes::Output outs;

spikes::Input ini;

spikes::Output outi;

bool spikesIn;
bool impulseIn;

int numElementsIn;
int numElementsOut;

vector <INT32> srcInds; 
vector <INT32> dstInds; 

bool portFound;

vector < vector <INT32> > spikeInds; 
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
			DataMLNode nodeState(&xmlNode);

			// obtain the parameters
			VDOUBLE size = nodeState.getField("sizeIn").getArrayDOUBLE();
			numElementsIn = 1;
			for (int i = 0; i < size.size(); ++i) {
				numElementsIn *= size[i];
			}		

			size = nodeState.getField("sizeOut").getArrayDOUBLE();
			numElementsOut = 1;
			for (int i = 0; i < size.size(); ++i) {
				numElementsOut *= size[i];
			}	
			
			string binpath = nodeState.getField("binpath").getSTRING();

			// get the connectivity
			if (nodeState.hasField("_bin_file_name")) {

				string fileName = nodeState.getField("_bin_file_name").getSTRING();
				int _num_conn = (int) nodeState.getField("_bin_num_conn").getDOUBLE();
				bool _has_delay = (bool) nodeState.getField("_bin_has_delay").getDOUBLE();

				// open the file for reading
				FILE * binfile;
				// FIXME: We really need an absolute path here, generated at runtime
				fileName = binpath + fileName;
				binfile = fopen(fileName.c_str(),"rb");
				if (!binfile) {
					// That failed; try the default location for
					// spineml-2-brahms on a Unix system:
					fileName = "~/spineml-2-brahms/model/" + fileName;
					binfile = fopen(fileName.c_str(),"rb");
					if (!binfile) {
						berr << "Could not open connectivity file";
					}
				}

				srcInds.resize(_num_conn);
				dstInds.resize(_num_conn);
				/*if (_has_delay)
					delayForConnTemp.resize(_num_conn);*/
				for (int i_BRAHMS = 0; i_BRAHMS < _num_conn; ++i_BRAHMS) {
					size_t v = fread(&srcInds[i_BRAHMS], sizeof(unsigned int), 1, binfile);
					v = fread(&dstInds[i_BRAHMS], sizeof(unsigned int), 1, binfile);
					/*if (_has_delay)
						fread(&delayForConnTemp[i_BRAHMS], sizeof(unsigned int), 1, binfile);*/
				} 				
			} else {
				srcInds = nodeState.getField("src").getArrayINT32();
				dstInds = nodeState.getField("dst").getArrayINT32();
			}

			if (srcInds.size() != dstInds.size()) 
				berr << "Connectivity src and dst lists have different sizes";

			// sanity check
			for (UINT32 i = 0; i < srcInds.size(); ++i) {

				if (srcInds[i] >= numElementsIn) {
					berr << "Index out of range for connection " << float(i) << ": value=" << srcInds[i];
				} 
				if (dstInds[i] >= numElementsOut) {
					berr << "Index out of range for connection " << float(i) << ": value=" << dstInds[i];
				} 

			}
			
		
			spikesIn = false;
			impulseIn = false;
			portFound = false;

			return C_OK;


		}

		// CREATE THE PORTS
		case EVENT_INIT_CONNECT:
		{
		
			//	on each call
			int numInputs = iif.getNumberOfPorts();
			
			if (numInputs == 1 && portFound == false) {
				portFound = true;
		
				if (in.tryAttach(hComponent, "in")) {
					out.setName("out");
					out.create(hComponent);
					out.setStructure(TYPE_DOUBLE | TYPE_REAL, Dims(numElementsOut).cdims());
				}
				if (ins.tryAttach(hComponent,"inSpike")) {
					spikesIn = true;
					outs.setName("out");
					outs.create(hComponent);
					outs.setCapacity(numElementsIn*numElementsOut);
					
					// create lookup for spikes
					spikeInds.resize(numElementsIn);
					for (int i = 0; i < srcInds.size(); ++i) {
						spikeInds[srcInds[i]].push_back(dstInds[i]);			
					}
					
				}
				if (ini.tryAttach(hComponent,"inImpulse")) {
					impulseIn = true;
					outi.setName("out");
					outi.create(hComponent);
					outi.setCapacity(numElementsIn*numElementsOut*3);
				
					// create lookup for spikes
					spikeInds.resize(numElementsIn);
					for (int i = 0; i < srcInds.size(); ++i) {
						spikeInds[srcInds[i]].push_back(dstInds[i]);			
					}
				
				}
				
			}

			//	on last call
			if (event->flags & F_LAST_CALL)
			{
			}

			//	ok
			return C_OK;
		}

		case EVENT_RUN_SERVICE:
		{
			if (!spikesIn && !impulseIn) {
				DOUBLE * inData;
				inData = (DOUBLE*) in.getContent();
				
				DOUBLE * outData;
				outData = (DOUBLE *) out.getContent();
			
				// clear old data
				memset(outData, 0, 8*numElementsOut);
			
				for (UINT32 i = 0; i < srcInds.size(); ++i) {
					outData[dstInds[i]] += inData[srcInds[i]];
				}
			}
			if (spikesIn) 
			{
				INT32 * spikeData;
				UINT32 numSpikes;
				numSpikes = ins.getContent(spikeData);
			
				VINT32 outData;
				// for each input spike
				for (UINT32 i = 0; i < numSpikes; ++i) {
					// for each target of the source of that spike
					for (UINT32 j = 0; j < spikeInds[spikeData[i]].size(); ++j) {
						// add output spike to the list 
						outData.push_back(spikeInds[spikeData[i]][j]);
					}
				}
				
	
				outs.setContent(&(outData[0]), outData.size());
			}
			if (impulseIn) 
			{
				INT32 * data;
				UINT32 count;
				count = ini.getContent(data);
						
				DOUBLE totalImpulse = 0;
						
				VINT32 outData;
				// for each impulse
				for (UINT32 i = 0; i < count; i+=3) {
				
					// extract impulses and sum
					INT32 index;
					DOUBLE value;
					getImpulse(data,i,index,value);
					
					// for each target of the source of that impulse
					for (UINT32 j = 0; j < spikeInds[index].size(); ++j) {
						// add output impulse to the list 
						addImpulse(outData, spikeInds[index][j], value);
					}						
				
				}
	
				outi.setContent(&(outData[0]), outData.size());
			}
						
			//	ok
			return C_OK;
		}

	}

	//	if we service the event, we return C_OK
	//	if we don't, we should return S_NULL to indicate that we didn't
	return S_NULL;
}







//	include the second part of the overlay (it knows you've included it once already)
#include "brahms-1199.h"


