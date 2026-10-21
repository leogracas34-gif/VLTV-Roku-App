' VLTV Play - Roku | TV ao Vivo: categorias, canais, guia (agora/próximo), favoritos e prévia no canto.

sub iniciar()
    carregarI18n()
    m.cats = []
    m.canais = []
    m.catIdx = 0
    uiRet(m.top, 0, 0, 1920, 1080, uiFundo())
    uiLinha(m.top, 60, 30, 600, "TV ao Vivo", "font:LargeBoldSystemFont", uiTexto())
    m.listaCats = uiLista(m.top, 60, 120, 420, 9, 82)
    m.listaCats.observeField("itemSelected", "aoCategoria")
    m.listaCanais = uiLista(m.top, 500, 120, 600, 9, 82)
    m.listaCanais.observeField("itemSelected", "aoCanal")
    m.listaCanais.observeField("itemFocused", "aoFocoCanal")
    m.video = uiNo(m.top, "Video", { translation: [1140, 120], width: 720, height: 405, enableUI: false, mute: false })
    m.video.observeField("state", "aoEstadoPrevia")
    uiRet(m.top, 1140, 120, 720, 405, "0x000000FF").visible = false
    m.canalNome = uiNo(m.top, "Label", { translation: [1140, 545], width: 720, font: "font:MediumBoldSystemFont", color: uiTexto() })
    m.agora = uiNo(m.top, "Label", { translation: [1140, 595], width: 720, height: 100, wrap: true, maxLines: 2, font: "font:SmallSystemFont", color: uiTexto() })
    m.prox = uiNo(m.top, "Label", { translation: [1140, 700], width: 720, height: 100, wrap: true, maxLines: 3, font: "font:SmallSystemFont", color: uiSuave() })
    m.dica = uiNo(m.top, "Label", { translation: [1140, 960], width: 720, height: 70, wrap: true, font: "font:SmallSystemFont", color: uiSuave(), text: tx("OK: tela cheia   *: favorito") })
    m.msg = uiNo(m.top, "Label", { translation: [500, 450], width: 600, horizAlign: "center", font: "font:MediumSystemFont", color: uiSuave() })
    m.debounce = uiNo(m.top, "Timer", { repeat: false, duration: 0.7 })
    m.debounce.observeField("fire", "focoAssentou")
    m.listaCats.setFocus(true)
    carregarCats("cache")
end sub

sub retomar()
    if m.listaCanais.isInFocusChain() or m.listaCats.isInFocusChain() then return
    m.listaCanais.setFocus(true)
    focoAssentou()
end sub

sub encerrar()
    m.video.control = "stop"
end sub

' ── Categorias ──────────────────────────────────────────────────────
sub carregarCats(modo as String)
    t = chamar("ApiTask", "cats", { tipo: "ao_vivo", modo: modo }, "aoCats")
    m.modoCats = modo
    if modo = "cache" then m.msg.text = tx("Carregando...")
end sub

sub aoCats(ev as Object)
    chamarFim(ev)
    r = ev.getData()
    if r.ok = true then
        lista = filtrarCategoriasParental(r.lista)
        m.cats = lista
        textos = [tx("★ Favoritos")]
        for each c in lista
            nome = sv(c.category_name)
            if idiomaEn() then nome = trCat(nome)
            if c.adulta = true then nome = nome + "  (+18)"
            textos.Push(nome)
        end for
        m.listaCats.content = uiItensLista(textos)
        m.msg.text = ""
        if m.modoCats = "cache" then
            carregarCats("rede")
        end if
    else if m.modoCats = "cache" then
        carregarCats("rede")
    else
        m.msg.text = tx("Não foi possível carregar os canais.")
    end if
end sub

sub aoCategoria(ev as Object)
    i = ev.getData()
    m.catIdx = i
    if i = 0 then
        mostrarFavoritos()
        return
    end if
    c = m.cats[i - 1]
    if c.adulta = true and parentalBloqueando() then
        m.catPendente = c
        uiPin("Senha dos pais", pinOk)
        return
    end if
    abrirCategoria(c)
end sub

sub pinOk(pin as String)
    if pinConfere(pin) then
        m.global.parentalLiberado = true
        abrirCategoria(m.catPendente)
    else
        uiAviso("Senha incorreta", "A senha não confere.")
    end if
end sub

sub abrirCategoria(c as Object)
    m.catAtual = c
    m.msg.text = tx("Carregando...")
    t = chamar("ApiTask", "itens", { tipo: "ao_vivo", cat: sv(c.category_id), modo: "cache" }, "aoCanais")
    m.modoCanais = "cache"
    m.catAdulta = (c.adulta = true)
end sub

sub aoCanais(ev as Object)
    chamarFim(ev)
    r = ev.getData()
    if r.ok = true then
        novos = filtrarItensParental(r.lista, m.catAdulta)
        if not (m.modoCanais = "rede" and m.canais.Count() = novos.Count() and m.canaisDaCat = sv(m.catAtual.category_id)) then mostrarCanais(novos)
        m.canaisDaCat = sv(m.catAtual.category_id)
        if m.modoCanais = "cache" then
            m.modoCanais = "rede"
            chamar("ApiTask", "itens", { tipo: "ao_vivo", cat: sv(m.catAtual.category_id), modo: "rede" }, "aoCanais")
        end if
    else if m.modoCanais = "cache" then
        m.modoCanais = "rede"
        chamar("ApiTask", "itens", { tipo: "ao_vivo", cat: sv(m.catAtual.category_id), modo: "rede" }, "aoCanais")
    else
        m.msg.text = tx("Não foi possível carregar os canais.")
    end if
end sub

sub mostrarFavoritos()
    lista = []
    for each f in favoritosDaConta("canais")
        lista.Push({ stream_id: f.id, name: f.nome, stream_icon: f.capa, url: f.ext, category_id: f.cat })
    end for
    if lista.Count() = 0 then m.msg.text = tx("Nenhum favorito ainda. Aperte * em um canal.")
    mostrarCanais(lista)
end sub

sub mostrarCanais(lista as Object)
    m.canais = lista
    textos = []
    n = 0
    for each c in lista
        n = n + 1
        nome = sv(c.name)
        if ehFavorito("canais", sv(c.stream_id)) then nome = "★ " + nome
        textos.Push(nome)
    end for
    m.listaCanais.content = uiItensLista(textos)
    if lista.Count() > 0 then
        m.msg.text = ""
        m.listaCanais.setFocus(true)
    else if m.msg.text = "" then
        m.msg.text = tx("Nenhum canal nesta categoria.")
    end if
end sub

' ── Canal em foco: guia e prévia ────────────────────────────────────
sub aoFocoCanal(ev as Object)
    m.debounce.control = "stop"
    m.debounce.control = "start"
    m.agora.text = ""
    m.prox.text = ""
    i = ev.getData()
    if i >= 0 and i < m.canais.Count() then m.canalNome.text = sv(m.canais[i].name)
end sub

sub focoAssentou()
    i = m.listaCanais.itemFocused
    if i < 0 or i >= m.canais.Count() then return
    c = m.canais[i]
    t = chamar("ApiTask", "epg", { id: sv(c.stream_id), limite: 3 }, "aoEpg")
    marcarPedido("epg", t)
    tocarPrevia(c)
end sub

sub aoEpg(ev as Object)
    if not pedidoAtual("epg", ev) then return
    r = ev.getData()
    if r.ok <> true then return
    sep = separarEpg(r.lista, nowSec())
    if sep.atual <> invalid then
        m.agora.text = tx("Agora") + ": " + sv(sep.atual.inicio) + " " + sv(sep.atual.titulo)
    else
        m.agora.text = tx("Sem guia de programação")
    end if
    txt = ""
    for each p in sep.proximos
        if txt <> "" then txt = txt + Chr(10)
        txt = txt + sv(p.inicio) + " " + sv(p.titulo)
    end for
    if txt <> "" then m.prox.text = tx("Depois") + ":" + Chr(10) + txt
end sub

function urlCanal(c as Object, ext as String) as String
    s = sessaoLer()
    if s = invalid then return ""
    if s.modo = "m3u" then return sv(c.url)
    return urlStream(s, "live", sv(c.stream_id), ext)
end function

sub tocarPrevia(c as Object)
    u = urlCanal(c, "m3u8")
    if u = "" then return
    cn = CreateObject("roSGNode", "ContentNode")
    cn.url = u
    cn.streamFormat = "hls"
    if endsWith(LCase(u), ".ts") then cn.streamFormat = "ts"
    m.video.content = cn
    m.video.control = "play"
end sub

sub aoEstadoPrevia(ev as Object)
    ' Prévia com erro: não faz nada (a tela cheia tenta de outro jeito).
end sub

sub aoCanal(ev as Object)
    i = ev.getData()
    if i < 0 or i >= m.canais.Count() then return
    m.video.control = "stop"
    lista = []
    for each c in m.canais
        lista.Push({ id: sv(c.stream_id), nome: sv(c.name), url: sv(c.url) })
    end for
    uiAcao("abrir", { tela: "Player", args: { tipo: "live", lista: lista, indice: i } })
end sub

function onKeyEvent(tecla as String, pressionou as Boolean) as Boolean
    if not pressionou then return false
    if tecla = "right" and m.listaCats.hasFocus() and m.canais.Count() > 0 then
        m.listaCanais.setFocus(true)
        return true
    else if tecla = "left" and m.listaCanais.hasFocus() then
        m.listaCats.setFocus(true)
        return true
    else if tecla = "options" and m.listaCanais.hasFocus() then
        i = m.listaCanais.itemFocused
        if i >= 0 and i < m.canais.Count() then
            c = m.canais[i]
            alternarFavorito("canais", { id: sv(c.stream_id), nome: sv(c.name), capa: sv(c.stream_icon), ext: sv(c.url), cat: sv(c.category_id) })
            if m.catIdx = 0 then
                mostrarFavoritos()
            else
                mostrarCanais(m.canais)
                m.listaCanais.jumpToItem = i
            end if
        end if
        return true
    end if
    return false
end function
