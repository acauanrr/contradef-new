// SectionTracker.cpp
#include "SectionTracker.h"
#include <iomanip>
#include "EventData.h"
#include "Notifier.h"

namespace SectionTracker {

    std::vector<SectionInfo> knownSections;
    Notifier* globalNotifierPtr;

    VOID GetSectionInfo(IMG img)
    {
        std::stringstream out;

        out << std::endl << "[+] Informa��o de se��es..." << std::endl;
        out << "    Nome da imagem: " << std::string(IMG_Name(img)) << std::endl;

        int index = 0;
        for (SEC sec = IMG_SecHead(img); SEC_Valid(sec); sec = SEC_Next(sec), ++index)
        {
            std::string secName = SEC_Name(sec);
            secName = secName.empty() ? "[VAZIO]" : secName;
            ADDRINT secAddr = SEC_Address(sec);
            UINT64 secSize = SEC_Size(sec);

            out << "    Se��o [" << index << "]" << std::endl;
            out << "        Nome da se��o: " << secName << std::endl;
            out << "        Endere�o: 0x" << std::hex << static_cast<uint64_t>(secAddr) << std::dec << std::endl;
            out << "        Tamanho: " << static_cast<uint64_t>(secSize) << " bytes" << std::endl;

            out << "        Caracter�sticas: " << std::endl;
            if (SEC_IsExecutable(sec))
            {
                out << "            A se��o � execut�vel." << std::endl;
            }
            if (SEC_IsReadable(sec))
            {
                out << "            A se��o � leg�vel." << std::endl;
            }
            if (SEC_IsWriteable(sec))
            {
                out << "            A se��o � grav�vel." << std::endl;
            }

            SectionInfo info;
            info.name = secName;
            info.base = secAddr;
            info.size = secSize;

            knownSections.push_back(info);
        }

        out << "[*] Conclu�do" << std::endl << std::endl;
        out.flush();

        ExecutionInformation executionCompletedInfo = { out.str() };
        ExecutionEventData executionEvent(executionCompletedInfo);
        globalNotifierPtr->NotifyAll(&executionEvent);
    }

    VOID ImageLoad(IMG img, VOID* v)
    {
        if (IMG_IsMainExecutable(img))
        {
            GetSectionInfo(img);
        }
    }

    BOOL IsInKnownSection(ADDRINT addr)
    {
        for (const auto& sec : knownSections)
        {
            if (addr >= sec.base && addr < sec.base + sec.size)
                return TRUE;
        }
        return FALSE;
    }

    VOID Init(VOID* globalNotifier)
    {
        globalNotifierPtr = reinterpret_cast<Notifier*>(globalNotifier);
        IMG_AddInstrumentFunction(ImageLoad, 0);
    }

} // namespace SectionTracker
