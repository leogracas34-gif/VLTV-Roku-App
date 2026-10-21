' VLTV Play - Roku | Player em tela cheia: TV ao vivo (troca de canal, m3u8 -> ts), filmes e séries (continuar de onde parou,
' próximo episódio, créditos aprendidos, áudio e legenda).

sub iniciar()
    carregarI18n()
    a = m.top.args
    m.tipo = sv(a.tipo)
    m.reg = a.reg
    m.chave = sv(a.chave)
    m.serie = sv(a.serie)
    m.credSeg = 0
    m.fi = 0
    m.tent = 0
    m.fim = false
    m.sairFeito = false
    m.menuAberto = false

    uiRet(m.top, 0, 0, 1920, 1080, "0x000000FF")
    m.video = uiNo(m.top, "Video", { translation: [0, 0], width: 1920, height: 1080, enableUI: false, enableTrickPlay: false })
    m.video.observeField("state", "aoEstado")

    ' barra de informações
    m.barra = uiNo(m.top, "Group", { visible: false })
    uiRet(m.barra, 0, 840, 1920, 240, "0x000000C8")
    m.titulo = uiNo(m.barra, "Label", { translation: [80, 870], width: 1500, font: "font:LargeBoldSystemFont", color: uiTexto() })
    m.sub1 = uiNo(m.barra, "Label", { translation: [80, 935], width: 1760, font: "font:SmallSystemFont", color: uiSuave() })
    uiRet(m.barra, 80, 1000, 1760, 10, "0x3A3A40FF")
    m.progresso = uiRet(m.barra, 80, 1000, 1, 10, uiDestaque())
    m.tempos = uiNo(m.barra, "Label", { translation: [80, 1020], width: 1760, font: "font:SmallSystemFont", color: uiSuave() })

    m.aviso = uiNo(m.top, "Label", { translation: [160, 380], width: 1600, height: 240, horizAlign: "center", wrap: true, font: "font:LargeSystemFont", color: uiTexto(), visible: false })
    m.carregando = uiNo(m.top, "Label", { translation: [0, 500], width: 1920, horizAlign: "center", font: "font:LargeSystemFont", color: uiTexto(), text: tx("Carregando...") })

    ' botão "Próximo episódio"
    m.btProx = uiNo(m.top, "Group", { visible: false })
    uiRet(m.btProx, 1380, 720, 460, 80, uiDestaque())
    uiNo(m.btProx, "Label", { translation: [1380, 720], width: 460, height: 80, horizAlign: "center", vertAlign: "center", font: "font:MediumBoldSystemFont", color: "0xFFFFFFFF", text: tx("Próximo episódio  ▼") })

    m.escondeBarra = uiNo(m.top, "Timer", { repeat: false, duration: 5 })
    m.escondeBarra.observeField("fire", "esconderBarra")
    m.guarda = uiNo(m.top, "Timer", { repeat: true, duration: 15 })
    m.guarda.observeField("fire", "salvar")
    m.guarda.control = "start"
    m.relogio = uiNo(m.top, "Timer", { repeat: true, duration: 1 })
    m.relogio.observeField("fire", "tique")
    m.relogio.control = "start"

    if m.tipo = "live" then
        m.lista = a.lista
        m.i = iv(a.indice)
        tocarCanal()
    else
        if m.tipo = "filme" then
            m.fila = [{ id: "", url: sv(a.url), titulo: sv(a.titulo) }]
        else
            m.fila = a.fila
            if m.serie <> "" then chamar("ApiTask", "creditos_buscar", { serie: m.serie }, "aoCreditos")
        end if
        tocar(iv(a.pos))
    end if
    m.top.setFocus(true)
end sub

sub retomar()
    m.top.setFocus(true)
    m.menuAberto = false
end sub

sub encerrar()
    salvar()
    m.guarda.control = "stop"
    m.relogio.control = "stop"
    m.video.control = "stop"
end sub

' ── Tocar ───────────────────────────────────────────────────────────
function formatoDe(url as String) as String
    u = LCase(url)
    q = Instr(1, u, "?")
    if q > 0 then u = Left(u, q - 1)
    if endsWith(u, ".m3u8") then return "hls"
    if endsWith(u, ".mkv") then return "mkv"
    if endsWith(u, ".mp4") or endsWith(u, ".m4v") or endsWith(u, ".mov") then return "mp4"
    if endsWith(u, ".ts") then return "ts"
    return ""
end function

sub iniciarVideo(url as String, formato as String, titulo as String, posicao as Integer)
    m.aviso.visible = false
    m.carregando.visible = true
    cn = CreateObject("roSGNode", "ContentNode")
    cn.url = url
    cn.title = titulo
    if formato <> "" then cn.streamFormat = formato
    if posicao > 0 then cn.playStart = posicao
    m.video.content = cn
    m.video.control = "play"
end sub

sub tocar(posicao as Integer)
    item = m.fila[m.fi]
    m.fim = false
    m.titulo.text = sv(item.titulo)
    if m.tipo = "episodio" then
        m.chave = "ep:" + sv(item.id)
        m.titulo.text = sv(m.top.args.titulo)
        m.sub1.text = sv(item.titulo)
    else
        m.sub1.text = ""
    end if
    m.btProx.visible = false
    iniciarVideo(sv(item.url), formatoDe(sv(item.url)), sv(item.titulo), posicao)
    mostrarBarra()
end sub

function urlLive(c as Object, ext as String) as String
    s = sessaoLer()
    if s = invalid then return ""
    if s.modo = "m3u" then return sv(c.url)
    return urlStream(s, "live", sv(c.id), ext)
end function

' Canal ao vivo: primeiro m3u8 (HLS); se falhar, tenta .ts.
sub tocarCanal()
    c = m.lista[m.i]
    m.tent = 0
    m.titulo.text = sv(c.nome)
    m.sub1.text = tx("Canal") + " " + Str(m.i + 1).Trim() + " / " + Str(m.lista.Count()).Trim()
    tentarCanal()
    mostrarBarra()
    chamar("ApiTask", "epg", { id: sv(c.id), limite: 2 }, "aoEpgCanal")
end sub

sub tentarCanal()
    c = m.lista[m.i]
    s = sessaoLer()
    if s = invalid then return
    if s.modo = "m3u" then
        u = sv(c.url)
        f = formatoDe(u)
        if m.tent = 1 then
            if f = "hls" then f = "ts" else f = "hls"
        end if
        iniciarVideo(u, f, sv(c.nome), 0)
    else if m.tent = 0 then
        iniciarVideo(urlLive(c, "m3u8"), "hls", sv(c.nome), 0)
    else
        iniciarVideo(urlLive(c, "ts"), "ts", sv(c.nome), 0)
    end if
end sub

sub aoEpgCanal(ev as Object)
    chamarFim(ev)
    r = ev.getData()
    if r.ok <> true then return
    sep = separarEpg(r.lista, nowSec())
    if sep.atual <> invalid and m.tipo = "live" then
        m.sub1.text = sv(sep.atual.inicio) + " " + sv(sep.atual.titulo) + "     " + tx("Canal") + " " + Str(m.i + 1).Trim() + " / " + Str(m.lista.Count()).Trim()
    end if
end sub

sub aoCreditos(ev as Object)
    chamarFim(ev)
    r = ev.getData()
    if r.ok = true then m.credSeg = iv(r.seg)
end sub

' ── Estado do vídeo ─────────────────────────────────────────────────
sub aoEstado(ev as Object)
    est = ev.getData()
    if est = "playing" then
        m.carregando.visible = false
        m.aviso.visible = false
        m.tent = 0
        if m.tipo = "live" then m.tentouTs = false
    else if est = "buffering" then
        m.carregando.visible = true
    else if est = "paused" then
        mostrarBarra()
    else if est = "finished" then
        terminou()
    else if est = "error" then
        falhou()
    end if
end sub

sub falhou()
    m.carregando.visible = false
    if m.tipo = "live" and m.tent = 0 then
        m.tent = 1
        tentarCanal()
        return
    end if
    codigo = m.video.errorCode
    txt = "Não foi possível reproduzir. Tente outro título ou canal."
    if m.tipo <> "live" then
        u = LCase(sv(m.fila[m.fi].url))
        if endsWith(u, ".avi") or endsWith(u, ".wmv") or endsWith(u, ".flv") or endsWith(u, ".mpg") then
            txt = "Este formato de vídeo não é aceito pela Roku."
        end if
    end if
    if codigo = -3 or codigo = -5 then txt = "Sem conexão com o servidor. Confira a internet."
    m.aviso.text = tx(txt)
    m.aviso.visible = true
end sub

sub terminou()
    if m.tipo = "live" then
        tocarCanal()
        return
    end if
    m.fim = true
    salvar()
    if m.tipo = "episodio" and m.fi + 1 < m.fila.Count() then
        m.fi = m.fi + 1
        tocar(0)
    else
        sair()
    end if
end sub

sub sair()
    if m.sairFeito then return
    m.sairFeito = true
    uiAcao("voltar", invalid)
end sub

' ── Progresso ───────────────────────────────────────────────────────
sub salvar()
    if m.tipo = "live" or m.chave = "" or m.reg = invalid then return
    dur = Int(m.video.duration)
    posicao = Int(m.video.position)
    if m.fim then posicao = dur
    if dur <= 0 then return
    r = {}
    r.Append(m.reg)
    r.pos = posicao
    r.dur = dur
    r.t = nowSec()
    if m.tipo = "episodio" then r.ep = sv(m.fila[m.fi].titulo)
    progressoSalvar(m.chave, r)
end sub

sub tique()
    if m.video.state <> "playing" and m.video.state <> "paused" then return
    dur = m.video.duration
    posicao = m.video.position
    if m.barra.visible and m.tipo <> "live" and dur > 0 then
        m.progresso.width = Int(1760 * posicao / dur)
        m.tempos.text = hms(posicao) + " / " + hms(dur)
    end if
    ' botão do próximo episódio
    if m.tipo = "episodio" and m.fi + 1 < m.fila.Count() and dur > 0 then
        resta = dur - posicao
        limite = 45
        if m.credSeg > 0 then limite = m.credSeg
        m.btProx.visible = (resta <= limite and posicao > 60)
    end if
end sub

sub mostrarBarra()
    m.barra.visible = true
    m.escondeBarra.control = "stop"
    m.escondeBarra.control = "start"
    tique()
end sub

sub esconderBarra()
    if m.video.state = "paused" then return
    m.barra.visible = false
end sub

' ── Teclas ──────────────────────────────────────────────────────────
sub proximo(aprender as Boolean)
    if m.tipo <> "episodio" or m.fi + 1 >= m.fila.Count() then return
    resta = Int(m.video.duration - m.video.position)
    if aprender and m.serie <> "" and resta >= 5 and resta <= 600 and m.video.position > 60 then
        chamar("ApiTask", "creditos_enviar", { serie: m.serie, seg: resta }, "aoCreditosEnviados")
        m.credSeg = resta
    end if
    salvar()
    m.fi = m.fi + 1
    tocar(0)
end sub

sub aoCreditosEnviados(ev as Object)
    chamarFim(ev)
end sub

sub pular(seg as Integer)
    if m.tipo = "live" then return
    novo = m.video.position + seg
    if novo < 0 then novo = 0
    if m.video.duration > 0 and novo > m.video.duration - 3 then novo = m.video.duration - 3
    m.video.seek = novo
    mostrarBarra()
end sub

function onKeyEvent(tecla as String, pressionou as Boolean) as Boolean
    if not pressionou then return false
    if m.menuAberto then return false
    if tecla = "back" then
        return false
    else if tecla = "OK" or tecla = "play" then
        if m.tipo = "live" then
            mostrarBarra()
        else if m.video.state = "paused" then
            m.video.control = "resume"
            mostrarBarra()
        else
            m.video.control = "pause"
        end if
        return true
    else if tecla = "left" then
        pular(-10)
        return true
    else if tecla = "right" then
        pular(10)
        return true
    else if tecla = "rewind" then
        pular(-60)
        return true
    else if tecla = "fastforward" then
        pular(60)
        return true
    else if tecla = "replay" then
        pular(-10)
        return true
    else if tecla = "up" then
        if m.tipo = "live" then
            trocarCanal(-1)
        else
            mostrarBarra()
        end if
        return true
    else if tecla = "down" then
        if m.tipo = "live" then
            trocarCanal(1)
        else if m.btProx.visible then
            proximo(true)
        else
            mostrarBarra()
        end if
        return true
    else if tecla = "options" then
        abrirMenu()
        return true
    end if
    return false
end function

sub trocarCanal(d as Integer)
    n = m.lista.Count()
    if n < 2 then return
    m.i = (m.i + d + n) mod n
    tocarCanal()
end sub

' ── Menu (áudio, legenda, próximo episódio) ──────────────────────────
sub abrirMenu()
    m.menuAcoes = []
    textos = []
    audios = m.video.availableAudioTracks
    if audios <> invalid and audios.Count() > 1 then
        textos.Push(tx("Áudio"))
        m.menuAcoes.Push("audio")
    end if
    legendas = m.video.availableSubtitleTracks
    if legendas <> invalid and legendas.Count() > 0 then
        textos.Push(tx("Legenda"))
        m.menuAcoes.Push("legenda")
    end if
    if m.tipo = "episodio" and m.fi + 1 < m.fila.Count() then
        textos.Push(tx("Próximo episódio"))
        m.menuAcoes.Push("proximo")
    end if
    textos.Push(tx("Fechar"))
    m.menuAcoes.Push("fechar")
    mostrarDialogo(tx("Opções"), textos, "aoMenu")
end sub

sub mostrarDialogo(titulo as String, textos as Object, cb as String)
    d = CreateObject("roSGNode", "Dialog")
    d.title = titulo
    d.buttons = textos
    d.observeFieldScoped("buttonSelected", cb)
    d.observeFieldScoped("wasClosed", "aoDialogoFechado")
    m.menuAberto = true
    m.top.getScene().dialog = d
end sub

sub aoDialogoFechado(ev as Object)
    m.menuAberto = false
    m.top.setFocus(true)
end sub

sub aoMenu(ev as Object)
    d = ev.getRoSGNode()
    acao = m.menuAcoes[ev.getData()]
    d.close = true
    if acao = "audio" then
        m.trilhas = m.video.availableAudioTracks
        nomes = []
        for each t in m.trilhas
            n = sv(t.Name)
            if n = "" then n = sv(t.Language)
            nomes.Push(n)
        end for
        mostrarDialogo(tx("Áudio"), nomes, "aoEscolherAudio")
    else if acao = "legenda" then
        m.trilhas = m.video.availableSubtitleTracks
        nomes = [tx("Desligada")]
        for each t in m.trilhas
            n = sv(t.Description)
            if n = "" then n = sv(t.Language)
            nomes.Push(n)
        end for
        mostrarDialogo(tx("Legenda"), nomes, "aoEscolherLegenda")
    else if acao = "proximo" then
        proximo(true)
    end if
end sub

sub aoEscolherAudio(ev as Object)
    d = ev.getRoSGNode()
    i = ev.getData()
    d.close = true
    if i >= 0 and i < m.trilhas.Count() then m.video.audioTrack = sv(m.trilhas[i].Track)
end sub

sub aoEscolherLegenda(ev as Object)
    d = ev.getRoSGNode()
    i = ev.getData()
    d.close = true
    if i = 0 then
        m.video.globalCaptionMode = "Off"
    else if i - 1 < m.trilhas.Count() then
        m.video.globalCaptionMode = "On"
        m.video.subtitleTrack = sv(m.trilhas[i - 1].TrackName)
    end if
end sub
