' VLTV Play - Roku | Filmes e Séries: categorias, grade de capas, pesquisa local (índice da VPS), favoritos e continuar assistindo.

sub iniciar()
    carregarI18n()
    m.tipo = sv(m.top.args.tipo)
    m.cats = []
    m.itens = []
    m.indicePronto = false
    m.indiceFalhou = false
    titulo = "Filmes"
    if m.tipo = "series" then titulo = "Séries"
    uiRet(m.top, 0, 0, 1920, 1080, uiFundo())
    uiLinha(m.top, 60, 30, 600, titulo, "font:LargeBoldSystemFont", uiTexto())
    m.titCat = uiNo(m.top, "Label", { translation: [520, 40], width: 1300, font: "font:MediumSystemFont", color: uiSuave() })
    m.listaCats = uiLista(m.top, 60, 120, 420, 9, 82)
    m.listaCats.observeField("itemSelected", "aoCategoria")
    m.grade = uiNo(m.top, "MarkupGrid", {
        translation: [520, 110], itemComponentName: "CardItem", itemSize: [250, 440], itemSpacing: [14, 8],
        numColumns: 5, numRows: 2, drawFocusFeedback: false, focusBitmapUri: "pkg:/images/vazio.png",
        vertFocusAnimationStyle: "floatingFocus", visible: false
    })
    m.grade.observeField("itemSelected", "aoItem")
    m.msg = uiNo(m.top, "Label", { translation: [520, 400], width: 1300, height: 200, wrap: true, horizAlign: "center", font: "font:MediumSystemFont", color: uiSuave() })
    m.listaCats.setFocus(true)
    m.msg.text = tx("Carregando...")
    chamar("ApiTask", "cats", { tipo: m.tipo, modo: "cache" }, "aoCats")
    m.modoCats = "cache"
    ' Deixa a pesquisa pronta em segundo plano.
    s = sessaoLer()
    if s <> invalid and s.modo <> "m3u" then
        chamar("IndexTask", "preparar", { tipo: m.tipo }, "aoIndice")
    else
        m.indiceFalhou = true
    end if
end sub

sub retomar()
    if m.grade.visible and m.grade.isInFocusChain() then return
    m.listaCats.setFocus(true)
end sub

sub encerrar()
end sub

sub aoCats(ev as Object)
    chamarFim(ev)
    r = ev.getData()
    if r.ok = true then
        m.msg.text = ""
        m.cats = filtrarCategoriasParental(r.lista)
        textos = [tx("Pesquisar"), tx("★ Favoritos"), tx("Continuar assistindo")]
        for each c in m.cats
            nome = sv(c.category_name)
            if idiomaEn() then nome = trCat(nome)
            if c.adulta = true then nome = nome + "  (+18)"
            textos.Push(nome)
        end for
        m.listaCats.content = uiItensLista(textos)
        if m.modoCats = "cache" then
            m.modoCats = "rede"
            chamar("ApiTask", "cats", { tipo: m.tipo, modo: "rede" }, "aoCats")
        end if
    else if m.modoCats = "cache" then
        m.modoCats = "rede"
        chamar("ApiTask", "cats", { tipo: m.tipo, modo: "rede" }, "aoCats")
    else
        m.msg.text = tx("Não foi possível carregar as categorias.")
    end if
end sub

sub aoIndice(ev as Object)
    chamarFim(ev)
    r = ev.getData()
    if r.ok = true then
        m.indicePronto = true
    else
        m.indiceFalhou = true
    end if
    if m.buscaPendente <> invalid then
        q = m.buscaPendente
        m.buscaPendente = invalid
        if m.indicePronto then
            buscar(q)
        else
            mostrarMsg("A pesquisa não está disponível agora. Use as categorias.")
        end if
    end if
end sub

sub aoCategoria(ev as Object)
    i = ev.getData()
    if i = 0 then
        uiTeclado("Pesquisar", "Digite parte do nome.", sv(m.ultimaBusca), false, tecladoBusca)
    else if i = 1 then
        m.titCat.text = tx("★ Favoritos")
        lista = []
        for each f in favoritosDaConta(m.tipo)
            lista.Push({ id: sv(f.id), nome: sv(f.nome), capa: sv(f.capa), ext: sv(f.ext), nota: "", cat: sv(f.cat) })
        end for
        mostrarItens(lista, "Nenhum favorito ainda. No detalhe, escolha Favoritar.")
    else if i = 2 then
        m.titCat.text = tx("Continuar assistindo")
        lista = []
        for each r in continuarAssistindo(m.tipo)
            pct = 0
            if r.dur > 0 then pct = Int(r.pos * 100 / r.dur)
            lista.Push({ id: sv(r.tid), nome: sv(r.nome), capa: sv(r.capa), ext: sv(r.ext), nota: Str(pct).Trim() + "%", cat: "" })
        end for
        mostrarItens(lista, "Nada para continuar assistindo.")
    else
        c = m.cats[i - 3]
        if c.adulta = true and parentalBloqueando() then
            m.catPendente = c
            uiPin("Senha dos pais", pinOk)
            return
        end if
        abrirCategoria(c)
    end if
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
    m.catAdulta = (c.adulta = true)
    nome = sv(c.category_name)
    if idiomaEn() then nome = trCat(nome)
    m.titCat.text = nome
    mostrarMsg("Carregando...")
    m.modoItens = "cache"
    chamar("ApiTask", "itens", { tipo: m.tipo, cat: sv(c.category_id), modo: "cache" }, "aoItens")
end sub

sub aoItens(ev as Object)
    chamarFim(ev)
    r = ev.getData()
    if r.ok = true then
        lista = []
        for each x in filtrarItensParental(r.lista, m.catAdulta)
            lista.Push(normalizarItem(x))
        end for
        igual = (m.modoItens = "rede" and m.itens.Count() = lista.Count() and m.grade.visible)
        if not igual then mostrarItens(lista, "Nenhum título nesta categoria.")
        if m.modoItens = "cache" then
            m.modoItens = "rede"
            chamar("ApiTask", "itens", { tipo: m.tipo, cat: sv(m.catAtual.category_id), modo: "rede" }, "aoItens")
        end if
    else if m.modoItens = "cache" then
        m.modoItens = "rede"
        chamar("ApiTask", "itens", { tipo: m.tipo, cat: sv(m.catAtual.category_id), modo: "rede" }, "aoItens")
    else
        mostrarMsg("Não foi possível carregar os títulos.")
    end if
end sub

function normalizarItem(x as Object) as Object
    if m.tipo = "series" then
        return { id: sv(x.series_id), nome: sv(x.name), capa: urlImagem(x.cover), ext: "", nota: uiNota(x.rating), cat: sv(x.category_id) }
    end if
    ext = sv(x.container_extension)
    if sv(x.url) <> "" then ext = sv(x.url)   ' lista M3U: o endereço do vídeo vai no lugar da extensão
    return { id: sv(x.stream_id), nome: sv(x.name), capa: urlImagem(x.stream_icon), ext: ext, nota: uiNota(x.rating), cat: sv(x.category_id) }
end function

sub mostrarMsg(texto as String)
    m.grade.visible = false
    m.msg.text = tx(texto)
end sub

sub mostrarItens(lista as Object, vazio as String)
    m.itens = lista
    if lista.Count() = 0 then
        mostrarMsg(vazio)
        return
    end if
    raiz = CreateObject("roSGNode", "ContentNode")
    n = 0
    for each x in lista
        n = n + 1
        if n > 600 then exit for
        c = raiz.createChild("ContentNode")
        c.title = limparTitulo(x.nome)
        c.hdposterurl = x.capa
        c.shortdescriptionline1 = x.nota
    end for
    m.msg.text = ""
    m.grade.content = raiz
    m.grade.visible = true
    m.grade.setFocus(true)
end sub

' ── Pesquisa ────────────────────────────────────────────────────────
sub tecladoBusca(texto as String)
    q = texto.Trim()
    m.ultimaBusca = q
    if Len(q) < 2 then
        mostrarMsg("Digite pelo menos 2 letras.")
        return
    end if
    m.titCat.text = tx("Pesquisa") + ": " + q
    if m.indiceFalhou and not m.indicePronto then
        mostrarMsg("A pesquisa não está disponível agora. Use as categorias.")
        return
    end if
    if not m.indicePronto then
        m.buscaPendente = q
        mostrarMsg("Preparando a pesquisa. Na primeira vez pode levar alguns minutos; depois fica pronta na hora.")
        return
    end if
    buscar(q)
end sub

sub buscar(q as String)
    mostrarMsg("Buscando...")
    t = chamar("IndexTask", "buscar", { tipo: m.tipo, q: q, limite: 150 }, "aoBusca")
    marcarPedido("busca", t)
end sub

sub aoBusca(ev as Object)
    if not pedidoAtual("busca", ev) then return
    r = ev.getData()
    if r.ok <> true then
        mostrarMsg("A pesquisa não está disponível agora. Use as categorias.")
        return
    end if
    lista = []
    for each x in r.itens
        lista.Push({ id: sv(x.id), nome: sv(x.nome), capa: urlImagem(x.capa), ext: sv(x.ext), nota: uiNota(x.rating), cat: sv(x.cat) })
    end for
    mostrarItens(lista, "Nada encontrado.")
end sub

' ── Abrir título ────────────────────────────────────────────────────
sub aoItem(ev as Object)
    i = ev.getData()
    if i < 0 or i >= m.itens.Count() then return
    x = m.itens[i]
    uiAcao("abrir", { tela: "Detalhe", args: { tipo: m.tipo, id: x.id, nome: x.nome, capa: x.capa, ext: x.ext, cat: x.cat } })
end sub

function onKeyEvent(tecla as String, pressionou as Boolean) as Boolean
    if not pressionou then return false
    if tecla = "right" and m.listaCats.hasFocus() and m.grade.visible then
        m.grade.setFocus(true)
        return true
    else if (tecla = "left" or tecla = "back") and m.grade.hasFocus() then
        if tecla = "left" and m.grade.currFocusColumn > 0 then return false
        m.listaCats.setFocus(true)
        return true
    end if
    return false
end function

sub focar()
    if m.grade.visible and m.grade.isInFocusChain() then return
    if m.listaCats.isInFocusChain() then return
    m.listaCats.setFocus(true)
end sub
