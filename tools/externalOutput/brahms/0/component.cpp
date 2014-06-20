

/*
   Autogenerated BRAHMS process from 9ML description.
   Engine: XSLT
   Engine Author: Alex Cope 2012
   Node name:
*/


#define COMPONENT_CLASS_STRING "dev/SpineML/tools/externalOutput"
#define COMPONENT_CLASS_CPP dev_spineml_tools_externalOutput_0
#define COMPONENT_RELEASE 0
#define COMPONENT_REVISION 1
#define COMPONENT_ADDITIONAL "Author=SpineML_2_BRAHMS\n" "URL=Not supplied\n"
#define COMPONENT_FLAGS (F_NOT_RATE_CHANGER)

#define OVERLAY_QUICKSTART_PROCESS

//	include the component interface overlay (component bindings 1199)
#include "brahms-1199.h"

#include "rng.h"

//	alias data and util namespaces to something briefer
namespace numeric = std_2009_data_numeric_0;
namespace spikes = std_2009_data_spikes_0;
namespace rng = std_2009_util_rng_0;

using namespace std;

// for Linux sockets
#ifdef __WIN__

#else
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#endif

// the network client class
#include "../../../client.h"

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

    // Ports

    numeric::Input in;

    spikes::Input ins;

    spikes::Input ini;

    int size;

    spineMLNetworkClient client;

    dataTypes dataType;

    int numElementsIn;
    int numElementsOut;

    int portno;
    string server;
    string conn_name;

    vector < float > logT;
    vector < int > logIndex;
    vector < int > logMap;
    vector < double > logValues;
    FILE * logFile;

    string baseNameForLogs;

    bool logAll;

    float skip;
    float next_t;
    float dt;
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

        portno = nodeState.getField("port").getINT32();

        dataType = (dataTypes) nodeState.getField("type").getINT32();

        // get the server name
        if (nodeState.hasField("host")) {
            server = nodeState.getField("host").getSTRING();
        } else {
            server = "localhost";
        }

        // get the connection name
        if (nodeState.hasField("name")) {
            conn_name = nodeState.getField("name").getSTRING();
        } else {
            conn_name = "unknown";
        }

        // how often to send an output
        if (nodeState.hasField("skip")) {
            skip = nodeState.getField("skip").getDOUBLE();
        } else {
            skip = 0.01;
        }

        // Log base name
        baseNameForLogs = nodeState.getField("logfileNameForComponent").getSTRING();

        // check for logs
        if (nodeState.hasField("logInds")) {
            // we have a log! Read the data in:
            VINT32 tempLogData = nodeState.getField("logInds").getArrayINT32();

            switch (dataType) {
            case ANALOG:
                // resize the logmap:
                logMap = tempLogData;
                break;
            case EVENT:
                // logmap resize
                logMap.resize(size,-1);
                // set the logmap values - checking for out of range values
                for (unsigned int i = 0; i < tempLogData.size(); ++i) {
                    if (tempLogData[i]+0.5 >size) {
                        bout << "Attempting to log an index out of range" << D_WARN;
                    } else {
                        // set in mapping that the ith log value relates to the tempLogData[i]th neuron
                        logMap[(int) tempLogData[i]] = i;
                    }
                }
                break;
            case IMPULSE:
                break;
            }
        }

        if (nodeState.hasField("logAll")) {
            logAll = true;
        } else {
            logAll = false;
        }

        dt = 1000.0f * time->sampleRate.den / time->sampleRate.num; // time step in ms

        next_t = 0;

        return C_OK;
    }

    // CREATE THE PORTS
    case EVENT_INIT_CONNECT:
    {
        //	on first call
        if (event->flags & F_FIRST_CALL) {}

        //	on last call
        if (event->flags & F_LAST_CALL) {
            int inputs;
            switch (dataType) {
            case ANALOG:
            {
                inputs = iif.getNumberOfPorts();
                in.attach(hComponent, "in");
                const numeric::Structure * structure = in.getStructure();
                size = structure->dims.dims[0];
                // sanity check
                for (int i = 0; i < logMap.size(); ++i) {
                    if (logMap[i] > size-1) {
                        berr << "Requested index out of range on External Output";
                    }
                }
                // send fixed size


                if (logAll) {
                    if (!client.createClient(server, portno, size, dataType, RESP_AM_SOURCE, conn_name)) {
                        berr << client.getLastError();
                    }
                } else {
                    if (!client.createClient(server, portno, logMap.size(), dataType, RESP_AM_SOURCE)) {
                        berr << client.getLastError();
                    }
                }

            }
            break;

            case EVENT:
            {
                inputs = iif.getNumberOfPorts();
                ins.attach(hComponent, "in");
            }
            break;

            case IMPULSE:

                break;
            }
        }

        //	ok
        return C_OK;
    }

    case EVENT_RUN_SERVICE:
    {
        // current simulation time
        double t = float(time->now) * dt;

        //cout << "Output t = " << t << endl;

        switch (dataType) {
        case ANALOG:
        {
            // get internal data
            DOUBLE * data = (DOUBLE *) in.getContent();

            // implement skipping
            if (t > next_t - dt + 0.00001) {
                next_t = t + skip;

                if (logAll) {
                    client.sendData((char *) data, size*sizeof(double));
                } else {

                    VDOUBLE buffer;

                    // remap data
                    for (int i = 0; i < logMap.size(); ++i) {
                        buffer.push_back(data[logMap[i]]);
                    }

                    // send data
                    client.sendData((char *) &(buffer[0]), buffer.size()*sizeof(double));
                }
            }

        }
        break;
        case EVENT:
        {
            berr << "Not implemented yet";
            break;
        }
        case IMPULSE:
        {
            berr << "Not implemented yet";
            break;
        }
        }

        return C_OK;
    }

    case EVENT_RUN_STOP:
    {
        client.disconnectClient();
        return C_OK;
    }

    }

    //	if we service the event, we return C_OK
    //	if we don't, we should return S_NULL to indicate that we didn't
    return S_NULL;
}







//	include the second part of the overlay (it knows you've included it once already)
#include "brahms-1199.h"
