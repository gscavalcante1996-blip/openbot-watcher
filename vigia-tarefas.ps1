# Vigia de tarefas OpenBot - dispara o webhook quando a Muse escreve uma tarefa nova
# em tarefas/ (GTA, Geografia, Milagres, Bible Miracles ou Senior). Roda a cada 5 minutos via Tarefa Agendada.
# Na primeira execucao, registra os arquivos atuais como ja vistos, sem disparar
# (para nao disparar de novo uma tarefa que ja foi acionada na mao).
# So dispara arquivos .md com mais de 60 segundos (para o Drive terminar de sincronizar).
# Registra tudo em vigia-tarefas.log, na mesma pasta.
# Arquivo em ASCII puro (sem acentos e sem travessao).

$ErrorActionPreference = "Stop"

$pasta = $PSScriptRoot
$arquivoVistos = Join-Path $pasta "vigia-tarefas-vistos.txt"
$arquivoLog = Join-Path $pasta "vigia-tarefas.log"

function Escrever-Log($msg) {
    $agora = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $arquivoLog -Value "[$agora] $msg"
}

$pastas = @(
    @{ Tarefas = "G:\Meu Drive\projetos\equipe-gta\tarefas"; Script = "G:\Meu Drive\projetos\equipe-gta\disparar-webhook-gta.ps1"; Projeto = "GTA" },
    @{ Tarefas = "G:\Meu Drive\projetos\geografia-mapas\tarefas"; Script = "G:\Meu Drive\projetos\geografia-mapas\disparar-webhook-geografia.ps1"; Projeto = "Geografia" },
    @{ Tarefas = "G:\Meu Drive\projetos\milagres-biblia\tarefas"; Script = "G:\Meu Drive\projetos\milagres-biblia\disparar-webhook-milagres.ps1"; Projeto = "Milagres" },
    @{ Tarefas = "G:\Meu Drive\projetos\bible-miracles\tarefas"; Script = "G:\Meu Drive\projetos\bible-miracles\disparar-webhook-bible-miracles.ps1"; Projeto = "Bible Miracles" },
    @{ Tarefas = "G:\Meu Drive\projetos\senior\tarefas"; Script = "G:\Meu Drive\projetos\senior\disparar-webhook-senior.ps1"; Projeto = "Senior" }
)

$vistos = @{}
$primeiraVez = -not (Test-Path $arquivoVistos)
if (-not $primeiraVez) {
    Get-Content $arquivoVistos | ForEach-Object { $vistos[$_] = $true }
}

foreach ($p in $pastas) {
    if (-not (Test-Path $p.Tarefas)) {
        Escrever-Log ("Pasta nao encontrada: " + $p.Tarefas)
        continue
    }
    $arquivos = Get-ChildItem -Path $p.Tarefas -Filter *.md -File
    foreach ($a in $arquivos) {
        $chave = $p.Projeto + "|" + $a.Name
        if ($vistos.ContainsKey($chave)) { continue }
        if ($primeiraVez) {
            $vistos[$chave] = $true
            continue
        }
        $idadeSegundos = ((Get-Date) - $a.LastWriteTime).TotalSeconds
        if ($idadeSegundos -lt 60) { continue }
        $vistos[$chave] = $true
        Escrever-Log ("Tarefa nova (" + $p.Projeto + "): " + $a.Name + " - disparando webhook...")
        try {
            & powershell -ExecutionPolicy Bypass -File $p.Script -SemPausa
            Escrever-Log ("Webhook disparado (" + $p.Projeto + "): " + $a.Name)
        } catch {
            Escrever-Log ("Falha ao disparar (" + $p.Projeto + "): " + $a.Name + " - " + $_.Exception.Message)
        }
    }
}

$vistos.Keys | Set-Content -Path $arquivoVistos
if ($primeiraVez) { Escrever-Log "Primeira execucao: arquivos atuais registrados como ja vistos, sem disparar." }
