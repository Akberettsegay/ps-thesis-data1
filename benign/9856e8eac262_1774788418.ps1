# =======================================================================
# ... (Banner y Configuración Inicial - SIN CAMBIOS) ...
# Versión 2.0.3 - "El Analizador Pro"
# =======================================================================

# --- Configuración Inicial ---
$Host.UI.RawUI.WindowTitle = "ToolboxBS - Sistema Analyzer & Optimizer Pro v2.0.3"
# $ErrorActionPreference = "SilentlyContinue"

# --- Paleta de Colores Mejorada ---
$colores = @{
    "Titulo"      = "Magenta"; "Subtitulo"   = "Cyan"; "Normal"      = "White";
    "Exito"       = "Green"; "Advertencia" = "Yellow"; "Error"       = "Red";
    "Info"        = "Blue"; "Destacado"   = "DarkCyan"; "Importante"  = "DarkYellow";
    "Critico"     = "DarkRed"; "ProgresoBar" = "DarkCyan"; "ProgresoTxt" = "Green";
    "Input"       = "Cyan"; "Icono"       = "DarkGray";
}

# --- Funciones de Presentación ---
# [BANNER, Mostrar-Progreso, Mostrar-TextoAnimado - SIN CAMBIOS DESDE v2.0.1]
function Mostrar-Banner { [CmdletBinding()] param(); Clear-Host; Write-Host "`n`n"; $tituloLines = @( "  ███████╗██╗███████╗████████╗███████╗███╗   ███╗ █████╗      ", " ██╔════╝██║██╔════╝╚══██╔══╝██╔════╝████╗ ████║██╔══██╗     ", " ╚█████╗ ██║███████╗   ██║   █████╗  ██╔████╔██║███████║     ", "  ╚═══██╗██║╚════██║   ██║   ██╔══╝  ██║╚██╔╝██║██╔══██║     ", " ██████╔╝██║███████║   ██║   ███████╗██║ ╚═╝ ██║██║  ██║     ", " ╚═════╝ ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝     ", "  █████╗ ███╗   ██╗ █████╗ ██╗  ██╗    ██╗███████╗███████╗██████╗ ", " ██╔══██╗████╗  ██║██╔══██╗██║  ╚██╗ ██╔╝╚══███╔╝██╔════╝██╔══██╗", " ███████║██╔██╗ ██║███████║██║   ╚████╔╝    ███╔╝ █████╗  ██████╔╝", " ██╔══██║██║╚██╗██║██╔══██║██║    ╚██╔╝    ███╔╝  ██╔══╝  ██╔══██╗", " ██║  ██║██║ ╚████║██║  ██║███████╗██║    ███████╗███████╗██║  ██║", " ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝╚═╝    ╚══════╝╚══════╝╚═╝  ╚═╝" ); foreach($line in $tituloLines){Write-Host $line -ForegroundColor $colores.Titulo}; Write-Host " =================================================================" -ForegroundColor $colores.Subtitulo; Write-Host "           ANALYZER & OPTIMIZER - ToolboxBS Pro v2.0.3              " -ForegroundColor $colores.Subtitulo; Write-Host " =================================================================" -ForegroundColor $colores.Subtitulo; Write-Host "`n" }
function Mostrar-Progreso { [CmdletBinding()] param ([string]$Actividad, [int]$ProgresoPorcentaje); $longitud = 45; $completados = [math]::Floor($longitud * ($ProgresoPorcentaje / 100)); $restantes = $longitud - $completados; $barraProgreso = "[" + ("▓" * $completados) + ("░" * $restantes) + "]"; Write-Host "`r  " -NoNewline; Write-Host "⏳" -ForegroundColor $colores.Icono -NoNewline; Write-Host " $Actividad " -ForegroundColor $colores.Info -NoNewline; Write-Host $barraProgreso -ForegroundColor $colores.ProgresoBar -NoNewline; Write-Host " $($ProgresoPorcentaje)%" -ForegroundColor $colores.ProgresoTxt; if ($ProgresoPorcentaje -eq 100) { Write-Host "" } }
function Mostrar-TextoAnimado { [CmdletBinding()] param ([string]$Texto, [string]$Color = $colores.Normal, [int]$Velocidad = 8); foreach ($char in $Texto.ToCharArray()) { Write-Host $char -NoNewline -ForegroundColor $Color; Start-Sleep -Milliseconds $Velocidad }; Write-Host "" }

# --- Función Principal de Análisis ---

function Obtener-InfoSistema {
    [CmdletBinding()]
    param()

    Mostrar-TextoAnimado "🔍 INICIANDO ANÁLISIS PROFUNDO DEL SISTEMA..." -Color $colores.Subtitulo -Velocidad 10
    Write-Host "   ──────────────────────────────────────────────────" -ForegroundColor $colores.Subtitulo

    $resultados = @{
        # ... (igual que antes) ...
        SistemaOperativo = $null; ArquitecturaOS = $null; InstalacionDias = $null; Uptime = $null;
        RAM_GB = 0; RAM_Usada_GB = "N/A"; PorcentajeRAM = "N/A";
        CPU_Nombre = "N/A"; CPU_NucleosFisicos = 0; CPU_HilosLogicos = 0; UsoCPU = "N/A";
        TipoDisco_C = "N/A"; DiskSize_C_GB = "N/A"; DiskFree_C_GB = "N/A"; UsoDisco_C_Porcentaje = "N/A";
        TarjetasGraficas = @(); TieneGPUDedicada = $false;
        ProcesosTopCPU = @(); ProcesosTopRAM = @(); TotalProcesos = 0; SoftwareProfesionalDetectado = @{};
        AdaptadoresRedActivos = @(); ConexionesTCP_PorEstado = @();
        Recomendaciones = @();
        ErroresAnalisis = @()
    }
    $progresoActual = 0
    $prioridades = @{ "Muy Alta" = 0; "Alta" = 1; "Media" = 2; "Baja" = 3 }

    # --- Función auxiliar para añadir recomendación (CORREGIDA v2.0.3) ---
    function Add-Recommendation ($list, $priority, $type, $message) {
        # Asegurarse de que $list es un array (aunque debería serlo)
        $list = @($list)

        # Comprobar si el mensaje ya existe en la lista de hashtables
        $found = $false
        foreach ($item in $list) {
            # Comprobación defensiva por si acaso $item no es lo esperado
            if ($item -is [hashtable] -and $item.ContainsKey('Mensaje') -and $item.Mensaje -eq $message) {
                $found = $true
                break
            }
        }

        if (-not $found) {
            # Crear el nuevo elemento hashtable
            $newItem = @{
                "PrioridadNum" = $prioridades[$priority];
                "PrioridadStr" = $priority;
                "Tipo" = $type;
                "Mensaje" = $message
            }

            # --- Usar ArrayList para construir la nueva lista ---
            $newList = New-Object System.Collections.ArrayList
            # Añadir todos los elementos existentes de $list
            $newList.AddRange($list)
            # Añadir el nuevo elemento
            $newList.Add($newItem) | Out-Null

            # Devolver la nueva lista convertida a un array estándar de PowerShell
            return $newList.ToArray()

        } else {
            # Si ya existe, devolver la lista original sin cambios (asegurándose que es array)
            return $list
        }
    }


    # --- Análisis de Sistema Operativo ---
    # [SIN CAMBIOS]
    $progresoActual = 5; Mostrar-Progreso -Actividad "Verificando Sistema Operativo..." -ProgresoPorcentaje $progresoActual; try { $os = Get-CimInstance Win32_OperatingSystem -EA Stop; $resultados.SistemaOperativo = $os.Caption; $resultados.ArquitecturaOS = $os.OSArchitecture; $instalacion = $os.InstallDate; $resultados.InstalacionDias = (New-TimeSpan -Start $instalacion -End (Get-Date)).Days; $uptimeSpan = (Get-Date) - $os.LastBootUpTime; $resultados.Uptime = "$($uptimeSpan.Days)d $($uptimeSpan.Hours)h $($uptimeSpan.Minutes)m" } catch { $resultados.ErroresAnalisis += "Error OS: $($_.Exception.Message)" }

    # --- Análisis de Hardware (CPU y RAM) ---
    # [SIN CAMBIOS]
    $progresoActual = 15; Mostrar-Progreso -Actividad "Analizando CPU y Memoria RAM..." -ProgresoPorcentaje $progresoActual; try { $cpu = Get-CimInstance Win32_Processor -EA Stop; $resultados.CPU_Nombre = $cpu.Name.Trim(); $resultados.CPU_NucleosFisicos = $cpu.NumberOfCores; $resultados.CPU_HilosLogicos = $cpu.NumberOfLogicalProcessors } catch { $resultados.ErroresAnalisis += "Error CPU: $($_.Exception.Message)" }; try { $ram = Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum -EA Stop; $resultados.RAM_GB = [math]::Round($ram.Sum / 1GB, 1) } catch { $resultados.ErroresAnalisis += "Error RAM Total: $($_.Exception.Message)" }; try { $ramUsadaCounter = Get-Counter '\Memory\Committed Bytes' -EA Stop; $ramUsadaBytes = $ramUsadaCounter.CounterSamples.CookedValue; $resultados.RAM_Usada_GB = [math]::Round($ramUsadaBytes / 1GB, 2); if ($resultados.RAM_GB -gt 0) { $resultados.PorcentajeRAM = [math]::Round(($resultados.RAM_Usada_GB / $resultados.RAM_GB) * 100, 0) } } catch { $resultados.ErroresAnalisis += "Error RAM Usada: $($_.Exception.Message)"; $resultados.PorcentajeRAM = "N/A" }; try { $cpuLoadCounter = Get-Counter '\Processor Information(_Total)\% Processor Time' -EA SilentlyContinue; if ($null -eq $cpuLoadCounter) { $cpuLoadCounter = Get-Counter '\Processor(_Total)\% Processor Time' -EA Stop }; $cpuLoadSample = $cpuLoadCounter.CounterSamples.CookedValue; Start-Sleep -m 250; $cpuLoadSample = $cpuLoadCounter.CounterSamples.CookedValue; $resultados.UsoCPU = [math]::Round($cpuLoadSample, 1) } catch { $resultados.ErroresAnalisis += "Error Uso CPU: $($_.Exception.Message)"; $resultados.UsoCPU = "N/A" }

    # --- Análisis de Almacenamiento (Disco C: y tipo) ---
    # [SIN CAMBIOS]
    $progresoActual = 30; Mostrar-Progreso -Actividad "Revisando Almacenamiento Principal..." -ProgresoPorcentaje $progresoActual; try { $physicalDisks = Get-PhysicalDisk -EA SilentlyContinue; if ($physicalDisks -ne $null) { $partitionC = Get-Partition | Where-Object { $_.DriveLetter -eq 'C' } -EA SilentlyContinue; if ($null -ne $partitionC) { $diskNumberC = $partitionC.DiskNumber; $physicalDiskC = $physicalDisks | Where-Object { $_.DeviceID -eq $diskNumberC }; if ($null -ne $physicalDiskC) { if ($physicalDiskC.BusType -eq "NVMe") { $resultados.TipoDisco_C = "NVMe SSD 🚀" } elseif ($physicalDiskC.MediaType -eq 3) { $resultados.TipoDisco_C = "SATA SSD ⚡" } elseif ($physicalDiskC.MediaType -eq 4) { $resultados.TipoDisco_C = "HDD 💿" } elseif ($physicalDiskC.MediaType -eq 5) { $resultados.TipoDisco_C = "SCM ?" } elseif ($physicalDiskC.MediaType -eq 0) { $resultados.TipoDisco_C = "Desconocido ?" } elseif ($physicalDiskC.FriendlyName -match "SSD|NVMe") { $resultados.TipoDisco_C = "SSD (por nombre) ✨" } else { $resultados.TipoDisco_C = "Otro/Desconocido ($($physicalDiskC.MediaType)) ?" } } else { $resultados.TipoDisco_C = "Tipo N/A (Disco Físico)" } } else { $resultados.TipoDisco_C = "Tipo N/A (Partición C)" } } else {$resultados.TipoDisco_C = "Tipo N/A (No Discos Físicos)"} } catch { $resultados.ErroresAnalisis += "Error Tipo Disco: $($_.Exception.Message)"; $resultados.TipoDisco_C = "Tipo N/A (Error)" }; try { $diskC = Get-CimInstance Win32_LogicalDisk | Where-Object DeviceID -eq 'C:' -EA Stop; $resultados.DiskSize_C_GB = [math]::Round($diskC.Size / 1GB, 1); $resultados.DiskFree_C_GB = [math]::Round($diskC.FreeSpace / 1GB, 1); if ($resultados.DiskSize_C_GB -gt 0) { $resultados.UsoDisco_C_Porcentaje = [math]::Round(100 - (($resultados.DiskFree_C_GB / $resultados.DiskSize_C_GB) * 100), 0) } } catch { $resultados.ErroresAnalisis += "Error Info Disco C: $($_.Exception.Message)" }

    # --- Análisis de Tarjetas Gráficas ---
    # [SIN CAMBIOS]
    $progresoActual = 45; Mostrar-Progreso -Actividad "Identificando Tarjetas Gráficas..." -ProgresoPorcentaje $progresoActual; try { $gpus = Get-CimInstance -ClassName Win32_VideoController -EA Stop; if ($null -ne $gpus) { $gpus = @($gpus); foreach ($gpu in $gpus) { $gpuInfo = @{ Nombre = $gpu.Name.Trim(); VRAM_GB = "N/A"; Tipo = "Desconocido"; DriverVersion = $gpu.DriverVersion }; if ($gpu.AdapterRAM -gt 0) { $gpuInfo.VRAM_GB = [math]::Round($gpu.AdapterRAM / 1GB, 1) }; $esIntegrada = $gpu.Name -match "Intel|UHD|HD Graphics|Integrated|Microsoft Basic Display Adapter|AMD Radeon(?!\s*RX|\s*Pro)" -or ($gpu.AdapterRAM -gt 0 -and $gpu.AdapterRAM -lt 1GB); if ($esIntegrada) { $gpuInfo.Tipo = "Integrada 📉" } else { $gpuInfo.Tipo = "Dedicada 🔥"; $resultados.TieneGPUDedicada = $true }; $resultados.TarjetasGraficas += $gpuInfo } } } catch { $resultados.ErroresAnalisis += "Error GPUs: $($_.Exception.Message)" }

    # --- Análisis de Procesos y Software ---
    # [SIN CAMBIOS]
    $progresoActual = 65; Mostrar-Progreso -Actividad "Examinando Procesos y Software Clave..." -ProgresoPorcentaje $progresoActual; $procesos = Get-Process -EA SilentlyContinue; if ($null -ne $procesos) { $resultados.TotalProcesos = $procesos.Count; $resultados.ProcesosTopCPU = $procesos | Sort-Object -Property CPU -Descending | Select-Object -First 5 | ForEach-Object { @{ Name = $_.Name; RAM_MB = [math]::Round($_.WS / 1MB, 0) } }; $resultados.ProcesosTopRAM = $procesos | Sort-Object -Property WorkingSet -Descending | Select-Object -First 5 | ForEach-Object { @{ Name = $_.Name; RAM_MB = [math]::Round($_.WS / 1MB, 0) } }; $softwareExigentePatterns = @{ 'CAD/Diseño' = @('acad*.exe', 'revit*.exe', 'solidworks*.exe', 'inventor*.exe', 'catia*.exe', 'rhino*.exe', 'sketchup*.exe'); 'Edición Video' = @('premiere*.exe', 'afterfx*.exe', 'resolve*.exe', 'vegas*.exe', 'avid*.exe', 'finalcut*.exe', 'DaVinciResolve.exe'); 'Edición Imagen' = @('photoshop*.exe', 'illustrator*.exe', 'lightroom*.exe', 'gimp*.exe', 'coreldrw*.exe', 'affinity*.exe', 'captureone*.exe'); 'Modelado 3D' = @('3dsmax*.exe', 'maya*.exe', 'blender*.exe', 'zbrush*.exe', 'cinema4d*.exe', 'houdini*.exe', 'substance*.exe'); 'Desarrollo/IDE' = @('devenv.exe', '*studio*.exe', 'vscode*.exe', 'pycharm*.exe', 'intellij*.exe', 'eclipse*.exe', 'netbeans*.exe', 'androidstudio*.exe'); 'Virtualización' = @('vmware*.exe', 'virtualbox*.exe', 'vmconnect.exe', 'docker*.exe', 'wsl*.exe'); 'Gaming/Launcher' = @('steam*.exe', 'epicgames*.exe', 'battle.net*.exe', 'origin*.exe', 'eadesktop*.exe', 'ubisoft*.exe', 'riot*.exe', 'gog*.exe'); 'Streaming/OBS' = @('obs*.exe', 'streamlabs*.exe', 'xsplit*.exe'); 'Navegador (AltoUso)'= @('chrome.exe', 'firefox.exe', 'msedge.exe'); 'Colaboración' = @('ms-teams.exe', 'teams.exe', 'slack.exe', 'zoom*.exe'); 'Business Intel/DB' = @('PBIDesktop.exe', 'msmdsrv.exe', 'sqlservr.exe') }; $softwareDetectado = @{}; foreach ($proceso in $procesos) { foreach ($categoria in $softwareExigentePatterns.Keys) { foreach ($pattern in $softwareExigentePatterns[$categoria]) { if ($proceso.Name -like $pattern) { if (-not $softwareDetectado.ContainsKey($categoria)) { $softwareDetectado[$categoria] = @() }; if (-not ($softwareDetectado[$categoria].Name -contains $proceso.Name)) { $softwareDetectado[$categoria] += @{ Name = $proceso.Name; RAM_MB = [math]::Round($proceso.WS / 1MB, 0) } } } } } }; $resultados.SoftwareProfesionalDetectado = $softwareDetectado } else { $resultados.ErroresAnalisis += "No se pudieron obtener procesos." }

    # --- Análisis de Red ---
    # [SIN CAMBIOS]
    $progresoActual = 85; Mostrar-Progreso -Actividad "Comprobando Conexiones de Red..." -ProgresoPorcentaje $progresoActual; try { $resultados.AdaptadoresRedActivos = Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object Name, InterfaceDescription, Status, LinkSpeed, MacAddress -EA Stop } catch { $resultados.ErroresAnalisis += "Error Adaptadores Red: $($_.Exception.Message)" }; try { $resultados.ConexionesTCP_PorEstado = Get-NetTCPConnection -EA Stop | Group-Object State | Select-Object Name, Count } catch { $resultados.ErroresAnalisis += "Error Conexiones TCP: $($_.Exception.Message)" }

    # --- Generación de Recomendaciones Inteligentes ---
    $progresoActual = 95
    Mostrar-Progreso -Actividad "Generando Recomendaciones..." -ProgresoPorcentaje $progresoActual
    # CORREGIDO v2.0.3: Inicializar SIEMPRE como array vacío
    $recomendaciones = @()

    # --- IMPORTANTE v2.0.3: Actualizar la variable $recomendaciones en CADA llamada ---
    # Basadas en RAM
    if ($resultados.RAM_GB -lt 8) { $recomendaciones = Add-Recommendation $recomendaciones "Alta" "RAM" "RAM total baja ($($resultados.RAM_GB) GB). Mínimo 16GB recomendados para uso moderno." }
    elseif ($resultados.RAM_GB -lt 16) { $recomendaciones = Add-Recommendation $recomendaciones "Media" "RAM" "RAM ($($resultados.RAM_GB) GB) adecuada para tareas básicas. 16GB o más mejoran multitarea y software exigente." }
    if ($resultados.PorcentajeRAM -ne "N/A" -and $resultados.PorcentajeRAM -ge 85) { $recomendaciones = Add-Recommendation $recomendaciones "Alta" "RAM" "Uso de RAM muy alto ($($resultados.PorcentajeRAM)%). Cierre apps innecesarias o vigile procesos en 'Top RAM'." }
    elseif ($resultados.PorcentajeRAM -ne "N/A" -and $resultados.PorcentajeRAM -ge 70) { $recomendaciones = Add-Recommendation $recomendaciones "Media" "RAM" "Uso de RAM elevado ($($resultados.PorcentajeRAM)%). Vigile las aplicaciones que consumen más memoria." }

    # Basadas en Disco C:
    if ($resultados.DiskFree_C_GB -ne "N/A") {
        if ($resultados.DiskFree_C_GB -lt 15) { $recomendaciones = Add-Recommendation $recomendaciones "Muy Alta" "Disco" "¡ESPACIO CRÍTICO en Disco C: ($($resultados.DiskFree_C_GB) GB)! Urgente liberar espacio (mínimo 20-30GB libres)." }
        elseif ($resultados.DiskFree_C_GB -lt 30) { $recomendaciones = Add-Recommendation $recomendaciones "Alta" "Disco" "Espacio bajo en Disco C: ($($resultados.DiskFree_C_GB) GB). Libere espacio para mejor rendimiento y actualizaciones." }
        elseif ($resultados.UsoDisco_C_Porcentaje -ne "N/A" -and $resultados.UsoDisco_C_Porcentaje -ge 85) { $recomendaciones = Add-Recommendation $recomendaciones "Media" "Disco" "Disco C: bastante lleno ($($resultados.UsoDisco_C_Porcentaje)% usado). Considere limpieza o mover archivos." }
    }
    if ($resultados.TipoDisco_C -like "*HDD*") { $recomendaciones = Add-Recommendation $recomendaciones "Alta" "Disco" "Disco principal es HDD. Cambiar a SSD es la MEJORA de rendimiento más significativa posible." }

    # Basadas en Uptime
    if ($resultados.Uptime -match "(\d+)d" -and [int]$matches[1] -ge 7) { $recomendaciones = Add-Recommendation $recomendaciones "Baja" "Sistema" "Equipo encendido por $($matches[1]) días. Reiniciar periódicamente puede mejorar estabilidad y rendimiento." }

    # Basadas en CPU Usage
    if ($resultados.UsoCPU -ne "N/A" -and $resultados.UsoCPU -ge 80) { $recomendaciones = Add-Recommendation $recomendaciones "Media" "CPU" "Uso de CPU alto ($($resultados.UsoCPU)%) durante el análisis. Revise procesos activos si nota lentitud general." }

    # Basadas en GPU y Software Detectado
    $softwareQueNecesitaGPU = $resultados.SoftwareProfesionalDetectado.Keys | Where-Object { $_ -in @('CAD/Diseño', 'Edición Video', 'Modelado 3D', 'Gaming/Launcher', 'Streaming/OBS') }
    if ($softwareQueNecesitaGPU.Count -gt 0) {
        if (-not $resultados.TieneGPUDedicada) { $categorias = $softwareQueNecesitaGPU -join ', '; $recomendaciones = Add-Recommendation $recomendaciones "Muy Alta" "GPU" "Software exigente detectado ($categorias) SIN GPU dedicada. Rendimiento será MUY limitado. Considere añadir una GPU dedicada." }
        else {
            $gpuDedicada = $resultados.TarjetasGraficas | Where-Object { $_.Tipo -like "*Dedicada*" } | Select-Object -First 1
            if ($null -ne $gpuDedicada -and $gpuDedicada.VRAM_GB -ne "N/A") {
                 $vramGB = $gpuDedicada.VRAM_GB; $needsMoreVRAM = $false; $reason = ""
                 if (($softwareQueNecesitaGPU -contains 'Edición Video' -or $softwareQueNecesitaGPU -contains 'Modelado 3D') -and $vramGB -lt 8) { $needsMoreVRAM = $true; $reason = "Edición Video/3D (ideal 8GB+)" }
                 elseif (($softwareQueNecesitaGPU -contains 'CAD/Diseño' -or $softwareQueNecesitaGPU -contains 'Gaming/Launcher') -and $vramGB -lt 6) { $needsMoreVRAM = $true; $reason = "CAD/Gaming (ideal 6GB+)" }
                 elseif (($softwareQueNecesitaGPU -contains 'Streaming/OBS') -and $vramGB -lt 4) { $needsMoreVRAM = $true; $reason = "Streaming (ideal 4GB+)" }
                 if ($needsMoreVRAM) { $recomendaciones = Add-Recommendation $recomendaciones "Media" "GPU" "GPU dedicada ($($gpuDedicada.Nombre) - $vramGB GB VRAM) puede ser limitada para $reason. Considere una GPU con más VRAM si nota lentitud." }
            }
        }
    }

    # Recomendaciones específicas por software detectado y hardware general
    foreach ($categoria in $resultados.SoftwareProfesionalDetectado.Keys) {
        $softwareItems = $resultados.SoftwareProfesionalDetectado[$categoria]
        switch ($categoria) {
            'Edición Video' { if ($resultados.RAM_GB -lt 32) { $recomendaciones = Add-Recommendation $recomendaciones "Alta" "RAM" "Para Edición de Video se recomiendan 32GB+ de RAM (actual: $($resultados.RAM_GB) GB)." }; if ($resultados.CPU_HilosLogicos -lt 12) { $recomendaciones = Add-Recommendation $recomendaciones "Media" "CPU" "Edición de Video se beneficia de CPUs con 12+ hilos (actual: $($resultados.CPU_HilosLogicos))." } }
            'Modelado 3D' { if ($resultados.RAM_GB -lt 32) { $recomendaciones = Add-Recommendation $recomendaciones "Alta" "RAM" "Para Modelado 3D/Render se recomiendan 32GB+ de RAM (actual: $($resultados.RAM_GB) GB)." }; if ($resultados.CPU_HilosLogicos -lt 16) { $recomendaciones = Add-Recommendation $recomendaciones "Media" "CPU" "Render 3D se beneficia de CPUs con muchos hilos (16+) (actual: $($resultados.CPU_HilosLogicos))." } }
            'CAD/Diseño' { if ($resultados.RAM_GB -lt 16) { $recomendaciones = Add-Recommendation $recomendaciones "Media" "RAM" "Para CAD/Diseño complejo, 16GB+ de RAM es ideal (actual: $($resultados.RAM_GB) GB)." } }
            'Virtualización' { if ($resultados.RAM_GB -lt 16) { $recomendaciones = Add-Recommendation $recomendaciones "Alta" "RAM" "Para usar máquinas virtuales cómodamente, 16GB+ de RAM es necesario (actual: $($resultados.RAM_GB) GB)." }; if ($resultados.CPU_HilosLogicos -lt 8) { $recomendaciones = Add-Recommendation $recomendaciones "Media" "CPU" "Virtualización necesita CPUs con suficientes hilos (8+) (actual: $($resultados.CPU_HilosLogicos))." } }
            'Gaming/Launcher' { if ($resultados.RAM_GB -lt 16) { $recomendaciones = Add-Recommendation $recomendaciones "Media" "RAM" "Para gaming moderno, 16GB de RAM es el estándar (actual: $($resultados.RAM_GB) GB)." } }
            'Desarrollo/IDE' { if ($resultados.RAM_GB -lt 16) { $recomendaciones = Add-Recommendation $recomendaciones "Baja" "RAM" "Para desarrollo con IDEs/emuladores, 16GB de RAM dan más fluidez (actual: $($resultados.RAM_GB) GB)." } }
            'Colaboración' { if ($resultados.RAM_GB -lt 16) { $recomendaciones = Add-Recommendation $recomendaciones "Baja" "RAM" "Apps de colaboración (Teams, Slack) consumen RAM. 16GB+ ayuda si usa varias a la vez." } }
            'Business Intel/DB' { $swNameExample = if ($softwareItems.Count -gt 0) { $softwareItems[0].Name } else { $categoria }; if ($resultados.RAM_GB -lt 16) { $recomendaciones = Add-Recommendation $recomendaciones "Media" "RAM" "Herramientas como $swNameExample pueden consumir mucha RAM. 16GB+ recomendado, 32GB+ para modelos grandes." } }
        }
    }

    # Recomendación general de limpieza y revisión
    $recomendaciones = Add-Recommendation $recomendaciones "Baja" "Mantenimiento" "Realizar limpieza de disco (Archivos temporales, descargas, etc.) regularmente."
    $recomendaciones = Add-Recommendation $recomendaciones "Baja" "Mantenimiento" "Revisar programas que inician con Windows (Administrador de Tareas > Inicio) y desactivar los no esenciales."

    # Ordenar recomendaciones por prioridad
    $resultados.Recomendaciones = $recomendaciones | Sort-Object PrioridadNum

    # --- Finalizar Análisis ---
    $progresoActual = 100
    Mostrar-Progreso -Actividad "Análisis Completado. Generando informe..." -ProgresoPorcentaje $progresoActual
    Write-Host "   ──────────────────────────────────────────────────" -ForegroundColor $colores.Subtitulo

    # --- Mostrar Resultados Detallados ---
    # [SIN CAMBIOS DESDE v2.0.1]
    Write-Host "`n  ╔═══════════════════════════════════════════════════════════════════╗" -ForegroundColor $colores.Destacado; Write-Host "  ║                     📊 INFORME DETALLADO DEL SISTEMA                   ║" -ForegroundColor $colores.Destacado; Write-Host "  ╚═══════════════════════════════════════════════════════════════════╝" -ForegroundColor $colores.Destacado; Write-Host "`n  💻 " -NoNewline; Write-Host "SISTEMA OPERATIVO" -ForegroundColor $colores.Subtitulo; Write-Host "   ├─ Nombre: " -NoNewline; Write-Host $resultados.SistemaOperativo -ForegroundColor $colores.Destacado; Write-Host "   ├─ Arq.: " -NoNewline; Write-Host $resultados.ArquitecturaOS -ForegroundColor $colores.Destacado; Write-Host "   ├─ Instalado hace: " -NoNewline; Write-Host "$($resultados.InstalacionDias) días" -ForegroundColor $colores.Destacado; Write-Host "   └─ Tiempo Encendido (Uptime): " -NoNewline; Write-Host $resultados.Uptime -ForegroundColor $colores.Destacado; Write-Host "`n  🛠️ " -NoNewline; Write-Host "HARDWARE PRINCIPAL" -ForegroundColor $colores.Subtitulo; Write-Host "   ├─ CPU: " -NoNewline; Write-Host $resultados.CPU_Nombre -ForegroundColor $colores.Destacado; Write-Host "   │  └─ Núcleos/Hilos: " -NoNewline; Write-Host "$($resultados.CPU_NucleosFisicos) Físicos / $($resultados.CPU_HilosLogicos) Lógicos" -ForegroundColor $colores.Destacado; $colorCPU = $colores.Exito; if ($resultados.UsoCPU -ne "N/A") { if ($resultados.UsoCPU -ge 80) {$colorCPU = $colores.Error} elseif ($resultados.UsoCPU -ge 60) {$colorCPU = $colores.Advertencia} }; Write-Host "   │  └─ Uso CPU (Análisis): " -NoNewline; Write-Host "$($resultados.UsoCPU)%" -ForegroundColor $colorCPU; $colorRAM = $colores.Exito; if ($resultados.PorcentajeRAM -ne "N/A") { if ($resultados.PorcentajeRAM -ge 85) {$colorRAM = $colores.Error} elseif ($resultados.PorcentajeRAM -ge 70) {$colorRAM = $colores.Advertencia} }; Write-Host "   ├─ RAM: " -NoNewline; Write-Host "$($resultados.RAM_GB) GB" -ForegroundColor $colores.Destacado -NoNewline; Write-Host " (Usada: " -NoNewline; Write-Host "$($resultados.RAM_Usada_GB) GB / $($resultados.PorcentajeRAM)%" -ForegroundColor $colorRAM -NoNewline; Write-Host ")"; Write-Host "   ├─ Tarjeta(s) Gráfica(s):"; if ($resultados.TarjetasGraficas.Count -gt 0) { foreach ($gpu in $resultados.TarjetasGraficas) { $colorTipoGPU = if ($gpu.Tipo -like "*Dedicada*") {$colores.Exito} else {$colores.Advertencia}; Write-Host "   │  ├─ " -NoNewline; Write-Host $gpu.Nombre -ForegroundColor $colores.Destacado -NoNewline; Write-Host " - " -NoNewline; Write-Host $gpu.Tipo -ForegroundColor $colorTipoGPU -NoNewline; Write-Host " - " -NoNewline; if ($gpu.VRAM_GB -ne "N/A") { Write-Host "$($gpu.VRAM_GB) GB VRAM" -ForegroundColor $colores.Destacado } else { Write-Host "VRAM N/A" -ForegroundColor $colores.Advertencia }; Write-Host "   │  │  └─ Driver: " -NoNewline; Write-Host $gpu.DriverVersion -ForegroundColor $colores.Info } } else { Write-Host "   │  └─ "; Write-Host "No detectadas o error." -ForegroundColor $colores.Error }; Write-Host "   └─ Almacenamiento Principal (C:):"; $colorTipoDisco = if ($resultados.TipoDisco_C -like "*SSD*" -or $resultados.TipoDisco_C -like "*NVMe*") {$colores.Exito} elseif ($resultados.TipoDisco_C -like "*HDD*") {$colores.Advertencia} else {$colores.Info}; Write-Host "      ├─ Tipo: " -NoNewline; Write-Host $resultados.TipoDisco_C -ForegroundColor $colorTipoDisco; if ($resultados.DiskSize_C_GB -ne "N/A") { $colorEspacio = $colores.Exito; if ($resultados.DiskFree_C_GB -lt 15) {$colorEspacio = $colores.Error} elseif ($resultados.DiskFree_C_GB -lt 30) {$colorEspacio = $colores.Advertencia}; $longBarraDisco = 25; $completadosDisco = 0; $restantesDisco = $longBarraDisco; if ($resultados.UsoDisco_C_Porcentaje -ne "N/A") { $completadosDisco = [math]::Floor($longBarraDisco * ($resultados.UsoDisco_C_Porcentaje / 100)); $restantesDisco = $longBarraDisco - $completadosDisco }; $barraDisco = "[" + ("█" * $completadosDisco) + ("-" * $restantesDisco) + "]"; $colorBarraDisco = $colorEspacio; Write-Host "      ├─ Tamaño: " -NoNewline; Write-Host "$($resultados.DiskSize_C_GB) GB" -ForegroundColor $colores.Destacado -NoNewline; Write-Host " / Libre: " -NoNewline; Write-Host "$($resultados.DiskFree_C_GB) GB" -ForegroundColor $colorEspacio; Write-Host "      └─ Uso: " -NoNewline; Write-Host $barraDisco -ForegroundColor $colorBarraDisco -NoNewline; Write-Host " $($resultados.UsoDisco_C_Porcentaje)%" } else { Write-Host "      └─ "; Write-Host "No se pudo leer información del disco C:." -ForegroundColor $colores.Error }; Write-Host "`n  📈 " -NoNewline; Write-Host "PROCESOS Y SOFTWARE RELEVANTE ($($resultados.TotalProcesos) total)" -ForegroundColor $colores.Subtitulo; Write-Host "   ├─ Top 5 Consumo CPU (Histórico):"; if ($resultados.ProcesosTopCPU.Count -gt 0) { $i=1; foreach ($p in $resultados.ProcesosTopCPU) { Write-Host "   │  $i. " -NoNewline; Write-Host $p.Name -ForegroundColor $colores.Destacado -NoNewline; Write-Host " (RAM: $($p.RAM_MB) MB)"; $i++ } } else { Write-Host "   │  └─ "; Write-Host "N/A" -ForegroundColor $colores.Advertencia}; Write-Host "   ├─ Top 5 Consumo RAM (Actual - WS):"; if ($resultados.ProcesosTopRAM.Count -gt 0) { $i=1; foreach ($p in $resultados.ProcesosTopRAM) { $colorRAMProc = if ($p.RAM_MB -gt 1500) {$colores.Error} elseif ($p.RAM_MB -gt 800) {$colores.Advertencia} else {$colores.Normal}; Write-Host "   │  $i. " -NoNewline; Write-Host $p.Name -ForegroundColor $colores.Destacado -NoNewline; Write-Host " (" -NoNewline; Write-Host "RAM: $($p.RAM_MB) MB" -ForegroundColor $colorRAMProc -NoNewline; Write-Host ")"; $i++ } } else { Write-Host "   │  └─ "; Write-Host "N/A" -ForegroundColor $colores.Advertencia}; Write-Host "   └─ Software Exigente Detectado (En ejecución):"; if ($resultados.SoftwareProfesionalDetectado.Keys.Count -gt 0) { foreach ($categoria in $resultados.SoftwareProfesionalDetectado.Keys | Sort-Object) { Write-Host "      ├─ " -NoNewline; Write-Host $categoria -ForegroundColor $colores.Info; foreach ($sw in $resultados.SoftwareProfesionalDetectado[$categoria]) { $colorRAMSW = if ($sw.RAM_MB -gt 1500) {$colores.Advertencia} else {$colores.Normal}; Write-Host "      │  └─ " -NoNewline; Write-Host $sw.Name -ForegroundColor $colores.Destacado -NoNewline; Write-Host " (" -NoNewline; Write-Host "RAM: $($sw.RAM_MB) MB" -ForegroundColor $colorRAMSW -NoNewline; Write-Host ")" } } } else { Write-Host "      └─ "; Write-Host "Ninguno detectado en este momento." -ForegroundColor $colores.Exito }; Write-Host "`n  🌐 " -NoNewline; Write-Host "RED" -ForegroundColor $colores.Subtitulo; Write-Host "   ├─ Adaptadores Activos:"; if ($resultados.AdaptadoresRedActivos.Count -gt 0) { foreach($adapter in $resultados.AdaptadoresRedActivos) { Write-Host "   │  ├─ " -NoNewline; Write-Host $adapter.InterfaceDescription -ForegroundColor $colores.Destacado -NoNewline; Write-Host " ($($adapter.Name))"; Write-Host "   │  │  └─ Estado: " -NoNewline; Write-Host $adapter.Status -ForegroundColor $colores.Exito -NoNewline; Write-Host ", Velocidad: " -NoNewline; Write-Host $adapter.LinkSpeed -ForegroundColor $colores.Info -NoNewline; Write-Host ", MAC: " -NoNewline; Write-Host $adapter.MacAddress -ForegroundColor $colores.Info } } else { Write-Host "   │  └─ "; Write-Host "Ninguno activo o error." -ForegroundColor $colores.Advertencia }; Write-Host "   └─ Conexiones TCP (por estado):"; if ($resultados.ConexionesTCP_PorEstado.Count -gt 0) { $tcpStates = $resultados.ConexionesTCP_PorEstado | ForEach-Object { $namePart = $_.Name; $countPart = $_.Count; (Write-Host $namePart -ForegroundColor $colores.Destacado -PassThru) + ": $countPart" }; Write-Host "      └─ $($tcpStates -join ', ')" } else { Write-Host "      └─ "; Write-Host "No hay conexiones TCP activas significativas o error." }; if ($resultados.ErroresAnalisis.Count -gt 0) { Write-Host "`n  ⚠️ " -NoNewline; Write-Host "ERRORES DURANTE EL ANÁLISIS" -ForegroundColor $colores.Error; foreach ($err in $resultados.ErroresAnalisis) { Write-Host "   └─ "; Write-Host $err -ForegroundColor $colores.Error } }; if ($resultados.Recomendaciones.Count -gt 0) { Write-Host "`n  💡 " -NoNewline; Write-Host "RECOMENDACIONES (" -ForegroundColor $colores.Subtitulo -NoNewline; Write-Host "$($resultados.Recomendaciones.Count) encontradas" -ForegroundColor $colores.Normal -NoNewline; Write-Host ")" -ForegroundColor $colores.Subtitulo; Write-Host "   "; Write-Host "──────────────────────────────────────────────────" -ForegroundColor $colores.Icono; foreach ($rec in $resultados.Recomendaciones) { $colorPrioridad = switch ($rec.PrioridadStr) { "Muy Alta" { $colores.Critico } "Alta" { $colores.Error } "Media" { $colores.Advertencia } "Baja" { $colores.Info } default { $colores.Normal } }; $iconoPrioridad = switch ($rec.PrioridadStr) { "Muy Alta" { "🚨" } "Alta" { "🔥" } "Media" { "⚠️" } "Baja" { "ℹ️" } default { "➡️" } }; Write-Host "   $iconoPrioridad " -NoNewline; Write-Host "[$($rec.Tipo)] " -ForegroundColor $colores.Destacado -NoNewline; Write-Host $rec.Mensaje -ForegroundColor $colorPrioridad }; Write-Host "   "; Write-Host "──────────────────────────────────────────────────" -ForegroundColor $colores.Icono } else { Write-Host "`n  ✅ " -NoNewline; Write-Host "¡EXCELENTE! No se detectaron problemas significativos." -ForegroundColor $colores.Exito; Write-Host "   └─ El sistema parece estar optimizado y saludable según este análisis." }

    return $resultados
}

# --- Función de Optimización ---
# [SIN CAMBIOS DESDE v2.0.1]
function Optimizar-Sistema {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$InfoSistema
    )
    Write-Host "`n  ╔═══════════════════════════════════════════════════════════════════╗" -ForegroundColor $colores.Destacado; Write-Host "  ║                   🚀 OPTIMIZACIÓN BÁSICA DEL SISTEMA                ║" -ForegroundColor $colores.Destacado; Write-Host "  ╚═══════════════════════════════════════════════════════════════════╝" -ForegroundColor $colores.Destacado
    $accionesOptimizacion = @{ "LimpiezaTemp" = $false; "LimpiezaPrefetch" = $false; "OptimizarDisco" = $false; "LimpiarDNS" = $true; }; $prioridades = @{ "Muy Alta" = 0; "Alta" = 1; "Media" = 2; "Baja" = 3 }
    if ($InfoSistema.Recomendaciones | Where-Object {$_.Tipo -eq "Disco" -and $_.PrioridadNum -le $prioridades["Alta"]}) { $accionesOptimizacion.LimpiezaTemp = $true; $accionesOptimizacion.LimpiezaPrefetch = $true; }; if ($InfoSistema.Recomendaciones | Where-Object {$_.Tipo -eq "RAM" -and $_.PrioridadNum -le $prioridades["Alta"]}) { $accionesOptimizacion.LimpiezaTemp = $true; }; if ($InfoSistema.TipoDisco_C -ne "N/A") { $accionesOptimizacion.OptimizarDisco = $true; }
    if (-not ($accionesOptimizacion.Values -contains $true)) { Write-Host "`n  👍 " -NoNewline; Write-Host "No se requieren acciones de optimización automática en este momento." -ForegroundColor $colores.Exito; Write-Host "     (Las recomendaciones podrían ser de hardware, configuración manual o informativas)."; return }
    Write-Host "`n  📋 " -NoNewline; Write-Host "ACCIONES DE OPTIMIZACIÓN PROPUESTAS:" -ForegroundColor $colores.Subtitulo; if ($accionesOptimizacion.LimpiezaTemp) { Write-Host "   ✅ Limpiar archivos temporales (Usuario y Sistema)." -ForegroundColor $colores.Info }; if ($accionesOptimizacion.LimpiezaPrefetch) { Write-Host "   ✅ Limpiar caché de Prefetch (archivos .pf)." -ForegroundColor $colores.Info }; if ($accionesOptimizacion.OptimizarDisco) { $accionDisco = if ($InfoSistema.TipoDisco_C -like "*SSD*" -or $InfoSistema.TipoDisco_C -like "*NVMe*") {"Optimizar (TRIM)"} else {"Desfragmentar"}; Write-Host "   ✅ $accionDisco disco C:." -ForegroundColor $colores.Info }; if ($accionesOptimizacion.LimpiarDNS) { Write-Host "   ✅ Limpiar caché de DNS." -ForegroundColor $colores.Info }
    Write-Host ""; $promptMsg = " ¿Desea aplicar estas optimizaciones? [S/N]"; Write-Host "❓" -ForegroundColor $colores.Input -NoNewline; $respuesta = Read-Host -Prompt $promptMsg; if ($respuesta -notmatch '^[Ss]$') { Write-Host "`n  ❌ " -NoNewline; Write-Host "Operación cancelada por el usuario." -ForegroundColor $colores.Advertencia; return }
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent()); if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { Write-Host "`n  ⛔ " -NoNewline; Write-Host "¡ERROR!" -ForegroundColor $colores.Error -NoNewline; Write-Host " Estas optimizaciones requieren permisos de Administrador." -ForegroundColor $colores.Advertencia; Write-Host "     Por favor, ejecute el script de nuevo haciendo clic derecho -> Ejecutar como administrador." -ForegroundColor $colores.Advertencia; return }
    Write-Host "`n  🛡️ " -NoNewline; Write-Host "Creando Punto de Restauración..." -ForegroundColor $colores.Subtitulo; try { $fecha = Get-Date -Format "yyyyMMdd_HHmmss"; $descripcion = "ToolboxBS_PreOptimizacion_$fecha"; Checkpoint-Computer -Description $descripcion -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop; Write-Host "   ✅ " -NoNewline; Write-Host "Punto de restauración '$descripcion' creado." -ForegroundColor $colores.Exito } catch { Write-Host "   ❌ " -NoNewline; Write-Host "¡FALLÓ LA CREACIÓN DEL PUNTO DE RESTAURACIÓN!" -ForegroundColor $colores.Error -NoNewline; Write-Host " $($_.Exception.Message)" -ForegroundColor $colores.Critico; $promptConfirm = " ¿Continuar SIN punto de restauración? (¡RIESGOSO!) [S/N]"; Write-Host "❓" -ForegroundColor $colores.Input -NoNewline; $confirmacionSinPunto = Read-Host -Prompt $promptConfirm; if ($confirmacionSinPunto -notmatch '^[Ss]$') { Write-Host "`n  🛑 " -NoNewline; Write-Host "Optimización abortada debido a fallo en punto de restauración." -ForegroundColor $colores.Error; return }; Write-Host "   "; Write-Host "Continuando sin punto de restauración bajo responsabilidad del usuario." -ForegroundColor $colores.Advertencia }
    Write-Host "`n  ⚙️ " -NoNewline; Write-Host "APLICANDO OPTIMIZACIONES..." -ForegroundColor $colores.Subtitulo; $progresoOpt = 0; $accionesActivas = $accionesOptimizacion.Keys | Where-Object {$accionesOptimizacion[$_]}; $totalPasos = $accionesActivas.Count; $pasoActual = 0; function Update-OptProgress { param($activity) $pasoActual++; if ($totalPasos -gt 0) { $progresoOpt = [math]::Round(($pasoActual / $totalPasos) * 100) } else { $progresoOpt = 100 }; Mostrar-Progreso -Actividad $activity -ProgresoPorcentaje $progresoOpt }
    if ($accionesOptimizacion.LimpiezaTemp) { Update-OptProgress "Limpiando temporales de usuario..."; $tempUser = $env:TEMP; Get-ChildItem -Path $tempUser -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue; Update-OptProgress "Limpiando temporales del sistema..."; $tempSystem = "$env:windir\Temp"; Get-ChildItem -Path $tempSystem -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }
    if ($accionesOptimizacion.LimpiezaPrefetch) { Update-OptProgress "Limpiando caché Prefetch..."; $prefetchPath = "$env:windir\Prefetch"; Get-ChildItem -Path $prefetchPath -Filter "*.pf" -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue }
    if ($accionesOptimizacion.OptimizarDisco) { $accionDisco = if ($InfoSistema.TipoDisco_C -like "*SSD*" -or $InfoSistema.TipoDisco_C -like "*NVMe*") {"Optimizando (TRIM)"} else {"Desfragmentando"}; Update-OptProgress "$accionDisco Disco C: (puede tardar)..."; try { Optimize-Volume -DriveLetter C -Verbose -ErrorAction Stop *> $null; Write-Host "`n   " -NoNewline; Write-Host "✅ $accionDisco completado para C:." -ForegroundColor $colores.Exito } catch { Write-Host "`n   " -NoNewline; Write-Host "❌ Error durante $accionDisco en C:: $($_.Exception.Message)" -ForegroundColor $colores.Error } }
    if ($accionesOptimizacion.LimpiarDNS) { Update-OptProgress "Limpiando caché DNS..."; try { Clear-DnsClientCache -ErrorAction Stop } catch { Write-Host "`n   " -NoNewline; Write-Host "⚠️ No se pudo limpiar caché DNS: $($_.Exception.Message)" -ForegroundColor $colores.Advertencia } }
    if ($progresoOpt -lt 100) { Update-OptProgress "Finalizando..." }; Write-Host "`n  🏁 " -NoNewline; Write-Host "OPTIMIZACIÓN BÁSICA COMPLETADA." -ForegroundColor $colores.Exito; Write-Host "   "; Write-Host "Se recomienda REINICIAR el sistema para que todos los cambios surtan efecto." -ForegroundColor $colores.Advertencia
    $promptReinicio = " ¿Desea reiniciar ahora? [S/N]"; Write-Host "`n❓" -ForegroundColor $colores.Input -NoNewline; $respuestaReinicio = Read-Host -Prompt $promptReinicio; if ($respuestaReinicio -match '^[Ss]$') { Write-Host "`n  ⏳ " -NoNewline; Write-Host "Reiniciando en 10 segundos... (Presione Ctrl+C para cancelar)" -ForegroundColor $colores.Advertencia; Start-Sleep -Seconds 10; Restart-Computer -Force } else { Write-Host "`n  ℹ️ " -NoNewline; Write-Host "Reinicio cancelado. Recuerde reiniciar manualmente más tarde." -ForegroundColor $colores.Info }
}

# --- Flujo Principal del Script ---
# [SIN CAMBIOS DESDE v2.0.1]
function Iniciar-AnalizadorPro {
    [CmdletBinding()]
    param()

    Mostrar-Banner
    $informeSistema = Obtener-InfoSistema

    if ($null -ne $informeSistema -and $null -ne $informeSistema.SistemaOperativo) {
        Optimizar-Sistema -InfoSistema $informeSistema
    } else {
        Write-Host "`n  ❌ " -NoNewline; Write-Host "El análisis inicial falló gravemente. No se puede continuar con la optimización." -ForegroundColor $colores.Critico
        if ($null -ne $informeSistema -and $informeSistema.ErroresAnalisis.Count -gt 0) {
             Write-Host "`n  ⚠️ " -NoNewline; Write-Host "ERRORES DURANTE EL ANÁLISIS:" -ForegroundColor $colores.Error
             foreach ($err in $informeSistema.ErroresAnalisis) { Write-Host "   └─ "; Write-Host $err -ForegroundColor $colores.Error }
        }
    }

    Write-Host "`n`n  "; Write-Host "--- Fin del Script ---" -ForegroundColor $colores.Subtitulo
    Write-Host "  Presione cualquier tecla para salir..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# --- Punto de Entrada ---
Iniciar-AnalizadorPro