' VLTV Play - Roku | TV ao Vivo igual à da LG: categorias 380 | canais 420 | coluna da prévia 940 com informações.
' Setas: cima/baixo movem o destaque, OK nas categorias abre, direita entra nos canais e na estrela.
' OK no canal toca na prévia; OK no canal que já toca abre em tela cheia. * (opções) favorita.

sub iniciar()
    carregarI18n()
    m.cats = []
    m.canais = []
    m.catCarregada = -1
    m.tocando = invalid
    m.foco = "cat"
    m.estrela = false
    m.falhaCats = false
    m.idReq = 0

    vkFundo(m.top)
    m.pc = vkPainel(m.top, 60, 60, 380, 960, tx("Categorias"), true)
    m.pk = vkPainel(m.top, 470, 60, 420, 960, tx("Canais"), true)
    m.lc = vkLista(m.pc.grupo, 23, 83, 334, 850, 84, 6, 27)
    m.lk = vkLista(m.pk.grupo, 23, 83, 374, 850, 84, 6, 27)
    m.lk.ativo = false

    ' coluna da prévia
    vkRet(m.top, 920, 60, 940, 529, cBorda())
    vkRet(m.top, 922, 62, 936, 525, "0x000000FF")
    m.video = uiNo(m.top, "Video", { translation: [922, 62], width: 936, height: 525, enableUI: false, mute: false })
    m.avisoVideo = vkTxt(m.top, 922, 280, 936, 60, "", 30, false, cTexto(), "center")
    m.iNome = vkTxt(m.top, 928, 605, 924, 44, "", 36, true, cTexto(), "left")
    m.iAgora = vkTxt(m.top, 928, 657, 924, 40, "", 28, true, cClaro(), "left")
    m.iDesc = vkTxtM(m.top, 928, 705, 924, 64, "", 24, false, cSuave(), 2, "left")
    m.iProx = []
    for i = 0 to 6
        h = vkTxt(m.top, 928, 780 + i * 39, 220, 39, "", 26, false, cSuave(), "left")
        t = vkTxt(m.top, 1070, 780 + i * 39, 782, 39, "", 26, false, cTexto(), "left")
        m.iProx.Push({ h: h, t: t })
    end for
    m.timerEpg = uiNo(m.top, "Timer", { repeat: false, duration: 60 })
    m.timerEpg.observeField("fire", "recarregarEpg")

    vkListaItens(m.lc, [{ msg: true, nome: tx("Carregando categorias...") }])
    carregarCats("cache")
    m.top.setFocus(true)
end sub

sub retomar()
    m.top.setFocus(true)
    if m.tocando <> invalid then tocarPrevia(m.tocando)
end sub

sub focar()
    m.top.setFocus(true)
end sub

sub encerrar()
    m.video.control = "stop"
    m.timerEpg.control = "stop"
end sub

' ── Categorias ──────────────────────────────────────────────────────
sub carregarCats(modo as String)
    chamar("ApiTask", "cats", { tipo: "ao_vivo", modo: modo }, "aoCats")
    m.modoCats = modo
end sub

function categoriaTrancada(c as Dynamic) as Boolean
    if c = invalid then return false
    return c.adulta = true and parentalBloqueando()
end function

sub desenharCats()
    itens = []
    for each c in m.cats
        if c.especial = "fav" then
            itens.Push({ nome: tx("Favoritos"), icone: "pkg:/images/ui/i_estrela.png", iconeW: 34, iconeH: 34, iconeCor: cOuro() })
        else
            nome = sv(c.category_name)
            if idiomaEn() then nome = trCat(nome)
            it = { nome: nome }
            if categoriaTrancada(c) then it.cad = true
            itens.Push(it)
        end if
    end for
    for i = 0 to itens.Count() - 1
        if i = m.catCarregada then itens[i].marca = "claro"
    end for
    m.lc.ativo = (m.foco = "cat")
    vkListaItens(m.lc, itens)
end sub

sub aoCats(ev as Object)
    chamarFim(ev)
    r = ev.getData()
    if r.ok = true then
        primeira = (m.cats.Count() = 0)
        filtradas = filtrarCategoriasParental(r.lista)
        cats = [{ category_id: "__fav__", category_name: "Favoritos", especial: "fav" }]
        for each c in filtradas
            cats.Push(c)
        end for
        m.cats = cats
        m.falhaCats = false
        desenharCats()
        if primeira then
            inicio = 1
            if favoritosDaConta("canais").Count() > 0 then inicio = 0
            while inicio < cats.Count() - 1 and categoriaTrancada(cats[inicio])
                inicio = inicio + 1
            end while
            if categoriaTrancada(cats[inicio]) or inicio >= cats.Count() then inicio = 0
            vkListaIr(m.lc, inicio)
            carregarCanais(inicio)
        end if
        if m.modoCats = "cache" then carregarCats("rede")
    else if m.modoCats = "cache" then
        carregarCats("rede")
    else
        if m.cats.Count() = 0 then
            m.falhaCats = true
            vkListaItens(m.lc, [{ msg: true, nome: tx("Não foi possível carregar as categorias. Pressione OK para tentar de novo.") }])
        end if
    end if
end sub

sub escolherCategoria()
    if m.falhaCats then
        m.falhaCats = false
        vkListaItens(m.lc, [{ msg: true, nome: tx("Carregando categorias...") }])
        carregarCats("rede")
        return
    end if
    i = m.lc.idx
    c = m.cats[i]
    if categoriaTrancada(c) then
        uiSenha("Categoria +18", "Digite a senha para abrir.", senhaCategoriaOk)
        return
    end if
    if i = m.catCarregada and m.canais.Count() > 0 then return
    carregarCanais(i)
end sub

sub senhaCategoriaOk()
    desenharCats()
    carregarCanais(m.lc.idx)
end sub

' ── Canais ──────────────────────────────────────────────────────────
sub carregarCanais(i as Integer)
    c = m.cats[i]
    if c = invalid then return
    m.idReq = m.idReq + 1
    m.catCarregada = i
    m.catAtual = c
    desenharCats()
    t = sv(c.category_name)
    if idiomaEn() then t = trCat(t)
    if c.especial = "fav" then t = tx("Favoritos")
    m.pk.titulo.text = t
    m.estrela = false
    if c.especial = "fav" then
        mostrarFavoritos()
        return
    end if
    m.canais = []
    vkListaItens(m.lk, [{ msg: true, nome: tx("Carregando canais...") }])
    m.modoCanais = "cache"
    m.catAdulta = (c.adulta = true)
    m.reqAtual = m.idReq
    chamar("ApiTask", "itens", { tipo: "ao_vivo", cat: sv(c.category_id), modo: "cache" }, "aoCanais")
end sub

sub aoCanais(ev as Object)
    chamarFim(ev)
    if m.reqAtual <> m.idReq then return
    r = ev.getData()
    if r.ok = true then
        novos = filtrarItensParental(r.lista, m.catAdulta)
        igual = (m.modoCanais = "rede" and m.canais.Count() = novos.Count())
        if not igual then aplicarCanais(novos, true)
        if m.modoCanais = "cache" then
            m.modoCanais = "rede"
            chamar("ApiTask", "itens", { tipo: "ao_vivo", cat: sv(m.catAtual.category_id), modo: "rede" }, "aoCanais")
        end if
    else if m.modoCanais = "cache" then
        m.modoCanais = "rede"
        chamar("ApiTask", "itens", { tipo: "ao_vivo", cat: sv(m.catAtual.category_id), modo: "rede" }, "aoCanais")
    else
        m.canais = []
        vkListaItens(m.lk, [{ msg: true, nome: tx("Não foi possível carregar os canais. Pressione OK para tentar de novo.") }])
    end if
end sub

sub mostrarFavoritos()
    lista = []
    for each f in favoritosDaConta("canais")
        lista.Push({ stream_id: f.id, name: f.nome, stream_icon: f.capa, url: f.ext, category_id: f.cat })
    end for
    if lista.Count() = 0 then
        m.canais = []
        vkListaItens(m.lk, [{ msg: true, nome: tx("Nenhum canal favorito ainda. Em qualquer canal, aperte → e depois OK na estrela (ou a tecla *).") }])
        return
    end if
    aplicarCanais(lista, true)
end sub

sub aplicarCanais(lista as Object, primeiraVez as Boolean)
    m.canais = lista
    if lista.Count() = 0 then
        vkListaItens(m.lk, [{ msg: true, nome: tx("Nenhum canal nesta categoria.") }])
        return
    end if
    m.lk.idx = 0
    desenharCanais()
    ' Primeira vez na tela: já começa a tocar o primeiro canal na mini tela.
    if m.tocando = invalid then tocar(lista[0])
end sub

sub desenharCanais()
    itens = []
    for each c in m.canais
        it = { nome: sv(c.name) }
        if urlImagem(c.stream_icon) <> "" then it.icone = urlImagem(c.stream_icon)
        if ehFavorito("canais", sv(c.stream_id)) then it.estrela = 2 else it.estrela = 1
        if m.tocando <> invalid then
            if sv(m.tocando.stream_id) = sv(c.stream_id) then it.marca = "ok"
        end if
        itens.Push(it)
    end for
    m.lk.ativo = (m.foco = "canais")
    m.lk.estrelaFoco = (m.estrela and m.foco = "canais")
    idx = m.lk.idx
    vkListaItens(m.lk, itens)
    vkListaIr(m.lk, idx)
end sub

sub trocarFoco(novo as String)
    m.foco = novo
    if novo <> "canais" then m.estrela = false
    m.lc.ativo = (novo = "cat")
    m.lk.ativo = (novo = "canais")
    m.lk.estrelaFoco = (m.estrela and novo = "canais")
    vkListaDesenhar(m.lc)
    vkListaDesenhar(m.lk)
end sub

sub moverCanal(passo as Integer)
    if m.canais.Count() = 0 then return
    vkListaIr(m.lk, m.lk.idx + passo)
end sub

sub alternarFavoritoCanal()
    if m.canais.Count() = 0 then return
    c = m.canais[m.lk.idx]
    agora = alternarFavorito("canais", { id: sv(c.stream_id), nome: sv(c.name), capa: sv(c.stream_icon), ext: sv(c.url), cat: sv(c.category_id) })
    if m.catAtual <> invalid and m.catAtual.especial = "fav" and not agora then
        idx = m.lk.idx
        mostrarFavoritos()
        if m.canais.Count() = 0 then
            trocarFoco("cat")
            return
        end if
        vkListaIr(m.lk, idx)
        return
    end if
    desenharCanais()
end sub

' ── Prévia e guia ───────────────────────────────────────────────────
sub tocar(c as Object)
    m.tocando = c
    m.iNome.text = sv(c.name)
    m.iAgora.text = ""
    m.iDesc.text = ""
    for each p in m.iProx
        p.h.text = ""
        p.t.text = ""
    end for
    desenharCanais()
    tocarPrevia(c)
    carregarEpg(c)
end sub

sub carregarEpg(c as Object)
    m.timerEpg.control = "stop"
    if sv(c.url) <> "" and sessaoModo() = "m3u" then return
    t = chamar("ApiTask", "epg", { id: sv(c.stream_id), limite: 10 }, "aoEpg")
    marcarPedido("epg", t)
end sub

function sessaoModo() as String
    s = sessaoLer()
    if s = invalid then return ""
    return sv(s.modo)
end function

sub recarregarEpg()
    if m.tocando <> invalid then carregarEpg(m.tocando)
end sub

sub aoEpg(ev as Object)
    if not pedidoAtual("epg", ev) then return
    r = ev.getData()
    if r.ok <> true then return
    sep = separarEpg(r.lista, nowSec())
    at = sep.atual
    if at <> invalid and sv(at.titulo) <> "" then
        q = ""
        if sv(at.inicio) <> "" then
            q = " (" + rotuloDiaEpg(at) + sv(at.inicio)
            if sv(at.fim) <> "" then q = q + " - " + sv(at.fim)
            q = q + ")"
        end if
        m.iAgora.text = tx("Agora") + q + " " + sv(at.titulo)
        m.iDesc.text = sv(at.descricao)
    else
        m.iAgora.text = tx("Sem informação de programação.")
        m.iDesc.text = ""
    end if
    quantos = 7
    if sv(m.iDesc.text) <> "" then quantos = 5
    n = 0
    for each p in sep.proximos
        if n < quantos and sv(p.titulo) <> "" then
            m.iProx[n].h.text = rotuloDiaEpg(p) + sv(p.inicio)
            m.iProx[n].t.text = sv(p.titulo)
            n = n + 1
        end if
    end for
    while n < 7
        m.iProx[n].h.text = ""
        m.iProx[n].t.text = ""
        n = n + 1
    end while
    ' Os próximos ficam logo abaixo da descrição (ou mais para cima, sem ela).
    base = 705
    if sv(m.iDesc.text) <> "" then base = 780
    for i = 0 to 6
        m.iProx[i].h.translation = [928, base + i * 39]
        m.iProx[i].t.translation = [1070 - 0, base + i * 39]
    end for
    m.timerEpg.duration = sep.espera / 1000
    m.timerEpg.control = "start"
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

sub abrirTelaCheia()
    i = m.lk.idx
    m.video.control = "stop"
    lista = []
    for each c in m.canais
        lista.Push({ id: sv(c.stream_id), nome: sv(c.name), url: sv(c.url) })
    end for
    uiAcao("abrir", { tela: "Player", args: { tipo: "live", lista: lista, indice: i } })
end sub

' ── Teclas ──────────────────────────────────────────────────────────
function onKeyEvent(tecla as String, pressionou as Boolean) as Boolean
    if not pressionou then return false
    if tecla = "back" then
        if m.estrela then
            m.estrela = false
            m.lk.estrelaFoco = false
            vkListaDesenhar(m.lk)
            return true
        else if m.foco = "canais" then
            voltarParaCategorias()
            return true
        end if
        return false
    end if
    if m.foco = "cat" then return teclaCategorias(tecla)
    return teclaCanais(tecla)
end function

sub voltarParaCategorias()
    if m.catCarregada >= 0 then vkListaIr(m.lc, m.catCarregada)
    trocarFoco("cat")
end sub

function teclaCategorias(tecla as String) as Boolean
    if tecla = "up" then
        if m.lc.idx > 0 then vkListaIr(m.lc, m.lc.idx - 1)
        return true
    else if tecla = "down" then
        vkListaIr(m.lc, m.lc.idx + 1)
        return true
    else if tecla = "right" then
        if m.falhaCats then
            escolherCategoria()
        else if m.canais.Count() > 0 then
            if m.catCarregada >= 0 then vkListaIr(m.lc, m.catCarregada)
            trocarFoco("canais")
        end if
        return true
    else if tecla = "OK" then
        escolherCategoria()
        return true
    end if
    return false
end function

function teclaCanais(tecla as String) as Boolean
    if tecla = "options" then
        alternarFavoritoCanal()
        return true
    end if
    if m.estrela then
        if tecla = "OK" then
            alternarFavoritoCanal()
            return true
        else if tecla = "left" then
            m.estrela = false
            m.lk.estrelaFoco = false
            vkListaDesenhar(m.lk)
            return true
        else if tecla = "right" then
            return true
        end if
    else if tecla = "right" then
        if m.canais.Count() > 0 then
            m.estrela = true
            m.lk.estrelaFoco = true
            vkListaDesenhar(m.lk)
        end if
        return true
    end if
    if tecla = "left" then
        voltarParaCategorias()
    else if tecla = "up" then
        moverCanal(-1)
    else if tecla = "down" then
        moverCanal(1)
    else if tecla = "rewind" then
        moverCanal(-8)
    else if tecla = "fastforward" then
        moverCanal(8)
    else if tecla = "OK" then
        if m.canais.Count() = 0 then
            if m.catAtual <> invalid then carregarCanais(m.catCarregada)
            return true
        end if
        c = m.canais[m.lk.idx]
        if m.tocando <> invalid and sv(m.tocando.stream_id) = sv(c.stream_id) then
            abrirTelaCheia()
        else
            tocar(c)
        end if
    else
        return false
    end if
    return true
end function
