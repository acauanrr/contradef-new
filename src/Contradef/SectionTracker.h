// SectionTracker.h
#pragma once

#include "pin.H"
#include <string>
#include <vector>
#include <fstream>

namespace SectionTracker {

    struct SectionInfo {
        std::string name;
        ADDRINT base;
        UINT64 size;
    };

    // Inicializa o rastreador de se��es (registra ImageLoad)
    VOID Init(VOID* globalNotifier);

    // Verifica se um endere�o pertence a uma se��o conhecida
    BOOL IsInKnownSection(ADDRINT addr);

    // Extrai informa��es sobre se��es e registra no arquivo
    VOID GetSectionInfo(IMG img);

} // namespace SectionTracker
