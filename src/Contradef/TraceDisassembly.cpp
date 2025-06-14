#include "TraceDisassembly.h"
#include "InstrumentationUtils.h"
#include "CallContext.h"

namespace TraceDisassembly {

    std::ofstream disassemblyTraceOut;

    VOID TraceInst(INS ins, VOID* v)
    {
        ADDRINT addr = INS_Address(ins);

        // Verificação para instrumentar apenas o executável principal, se aplicável
        if (instrumentOnlyMain && !IsMainExecutable(addr)) {
            return;
        }

        std::string disassembledInstr = INS_Disassemble(ins);

        if (KnobTraceDisassembly) {
            disassemblyTraceOut << INS_Address(ins) << " | " << disassembledInstr << std::endl;
        }
    }

    VOID Fini(INT32 code, VOID* v)
    {
        if (KnobTraceDisassembly && disassemblyTraceOut.is_open()) {
            disassemblyTraceOut.close();
        }
    }

    int InitTraceDisassembly(std::string pid, std::string filename)
    {
        if (KnobTraceDisassembly) {
            filename += "." + pid + ".disassembly.cdf";
            disassemblyTraceOut.open(filename.c_str());
            disassemblyTraceOut << std::hex << std::right;
            disassemblyTraceOut.setf(std::ios::showbase);
        }

        INS_AddInstrumentFunction(TraceInst, 0);
        PIN_AddFiniFunction(Fini, 0);

        return 0;
    }


}
