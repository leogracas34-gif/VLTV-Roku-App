' VLTV Play - Roku | Detalhe do filme/série: TMDB (título, sinopse, fundo), continuar de onde parou, favorito, temporadas e episódios.

sub iniciar()
    carregarI18n()
    a = m.top.args
    m.tipo = sv(a.tipo)
    m.id = sv(a.id)
    m.nomeBruto = sv(a.nome)
    m.capaUrl = sv(a.capa)
    m.ext = sv(a.ext)
    m.cat = sv(a.cat)
    m.temporadas = []
    m.eps = []
    m.tempIdx = 0
    m.titulo = limparTitulo(m.nomeBruto)

    uiRet(m.top, 0, 0, 1920, 1080, uiFundo())
    m.fundo = uiFoto(m.top, 0, 0, 1920, 1080, "", true)
    m.fundo.opacity = 0.35
    uiRet(m.top, 0, 0, 1920, 1080, "0x0A0A0CB0")
    m.capa = uiFoto(m.top, 70, 120, 300, 450, m.capaUrl, true)
    m.nome = uiNo(m.top, "Label", { translation: [420, 110], width: 1420, height: 130, wrap: true, maxLines: 2, font: "font:LargeBoldSystemFont", color: uiTexto(), text: m.titulo })
    m.meta = uiNo(m.top, "Label", { translation: [420, 250], width: 1420, font: "font:SmallSystemFont", color: uiSuave() })
    m.sinopse = uiNo(m.top, "Label", { translation: [420, 295], width: 1420, height: 150, wrap: true, maxLines: 4, font: "font:SmallSystemFont", color: uiTexto() })
    m.bt = uiBotoes(m.top, 420, 470, ["Assistir"], true)
    m.bt.minWidth = 260
    m.bt.observeField("buttonSelected", "aoBotao")
    m.msg = uiNo(m.top, "Label", { translation: [420, 570], width: 1420, font: "font:SmallSystemFont", color: uiSuave(), text: tx("Carregando...") })
    m.listaTemp = invalid
    m.listaEps = invalid
    m.bt.setFocus(true)
    atualizarBotoes()

    if m.tipo = "series" then
        m.fundoTitulo = true
        chamar("ApiTask", "info_serie", { id: m.id }, "aoInfoSerie")
    else
        chamar("ApiTask", "info_filme", { id: m.id }, "aoInfoFilme")
    end if
    chamar("TmdbTask", "detalhe", { tipo: m.tipo, id: m.id, nome: m.nomeBruto }, "aoTmdb")
end sub

sub retomar()
    atualizarBotoes()
    if m.listaEps <> invalid then desenharEpisodios()
    if m.bt.isInFocusChain() or (m.listaTemp <> invalid and m.listaTemp.isInFocusChain()) or (m.listaEps <> invalid and m.listaEps.isInFocusChain()) then return
    m.bt.setFocus(true)
end sub

sub encerrar()
end sub

' ── Botões ──────────────────────────────────────────────────────────
function chaveProgresso() as String
    return "filme:" + m.id
end function

sub atualizarBotoes()
    m.acoes = []
    textos = []
    if m.tipo = "filmes" then
        p = progressoDe(chaveProgresso())
        if p <> invalid and p.dur > 0 and p.pos > 20 and p.pos < p.dur - 90 then
            textos.Push(tx("Continuar de") + " " + hms(p.pos))
            m.acoes.Push("continuar")
            textos.Push(tx("Do início"))
            m.acoes.Push("inicio")
        else
            textos.Push(tx("Assistir"))
            m.acoes.Push("inicio")
        end if
    else
        r = proximoEpisodio()
        if r <> invalid then
            textos.Push(tx(r.rotulo))
            m.acoes.Push("serie")
        end if
    end if
    if ehFavorito(m.tipo, m.id) then
        textos.Push(tx("Remover dos favoritos"))
    else
        textos.Push(tx("Favoritar"))
    end if
    m.acoes.Push("fav")
    m.bt.buttons = textos
end sub

sub aoBotao(ev as Object)
    acao = m.acoes[ev.getData()]
    if acao = "fav" then
        alternarFavorito(m.tipo, { id: m.id, nome: m.nomeBruto, capa: m.capaUrl, ext: m.ext, cat: m.cat })
        atualizarBotoes()
    else if acao = "inicio" then
        tocarFilme(0)
    else if acao = "continuar" then
        p = progressoDe(chaveProgresso())
        tocarFilme(p.pos)
    else if acao = "serie" then
        r = proximoEpisodio()
        if r <> invalid then tocarEpisodio(r.t, r.e, r.pos)
    end if
end sub

' ── Filme ───────────────────────────────────────────────────────────
sub aoInfoFilme(ev as Object)
    chamarFim(ev)
    r = ev.getData()
    m.msg.text = ""
    if r.ok <> true then return
    info = r.info
    if r.dados <> invalid and sv(r.dados.container_extension) <> "" and not startsWith(m.ext, "http") then m.ext = sv(r.dados.container_extension)
    partes = []
    ano = sv(info.releasedate)
    if Len(ano) >= 4 then partes.Push(Left(ano, 4))
    if sv(info.duration) <> "" then partes.Push(sv(info.duration))
    n = uiNota(info.rating)
    if n <> "" then partes.Push("★ " + n)
    if sv(info.genre) <> "" then partes.Push(tx(trCat(sv(info.genre))))
    m.meta.text = partes.Join("  •  ")
    m.plotPainel = sv(info.plot)
    if sv(m.sinopse.text) = "" then m.sinopse.text = m.plotPainel
    if idadeAdulta(info) and parentalBloqueando() then
        ' filme +18 aberto por busca/destaque: pede a senha antes de tocar
        m.adulto = true
    end if
    if sv(info.backdrop_path) <> "" and m.fundo.uri = "" then m.fundo.uri = sv(info.backdrop_path)
end sub

sub tocarFilme(posicao as Integer)
    if m.adulto = true and parentalBloqueando() then
        m.posPendente = posicao
        uiPin("Senha dos pais", pinOk)
        return
    end if
    abrirPlayer(m.ext, posicao)
end sub

sub pinOk(pin as String)
    if pinConfere(pin) then
        m.global.parentalLiberado = true
        if m.tipo = "filmes" then
            abrirPlayer(m.ext, m.posPendente)
        else
            tocarEpisodio(m.epPendente.t, m.epPendente.e, m.epPendente.pos)
        end if
    else
        uiAviso("Senha incorreta", "A senha não confere.")
    end if
end sub

sub abrirPlayer(ext as String, posicao as Integer)
    s = sessaoLer()
    if s = invalid then return
    url = ext
    if not startsWith(LCase(ext), "http") then
        e = ext
        if e = "" then e = "mp4"
        url = urlStream(s, "movie", m.id, e)
    end if
    uiAcao("abrir", { tela: "Player", args: {
        tipo: "filme", url: url, titulo: m.titulo, chave: chaveProgresso(), pos: posicao,
        reg: { tipo: "filmes", tid: m.id, nome: m.nomeBruto, capa: m.capaUrl, ext: m.ext }
    } })
end sub

' ── TMDB ────────────────────────────────────────────────────────────
sub aoTmdb(ev as Object)
    chamarFim(ev)
    r = ev.getData()
    if r.ok <> true then
        if m.tmdbSinopse = invalid and sv(m.plotPainel) <> "" then m.sinopse.text = m.plotPainel
        return
    end if
    if sv(r.titulo) <> "" then
        m.titulo = sv(r.titulo)
        m.nome.text = m.titulo
    end if
    if sv(r.sinopse) <> "" then
        m.sinopse.text = sv(r.sinopse)
        m.tmdbSinopse = true
    end if
    if sv(r.fundo) <> "" then m.fundo.uri = sv(r.fundo)
end sub

' ── Série ───────────────────────────────────────────────────────────
sub aoInfoSerie(ev as Object)
    chamarFim(ev)
    r = ev.getData()
    m.msg.text = ""
    if r.ok <> true or r.temporadas.Count() = 0 then
        m.msg.text = tx("Não foi possível carregar os episódios.")
        return
    end if
    info = r.info
    partes = []
    ano = sv(info.releaseDate)
    if Len(ano) >= 4 then partes.Push(Left(ano, 4))
    n = uiNota(info.rating)
    if n <> "" then partes.Push("★ " + n)
    if sv(info.genre) <> "" then partes.Push(tx(trCat(sv(info.genre))))
    m.meta.text = partes.Join("  •  ")
    m.plotPainel = sv(info.plot)
    if sv(m.sinopse.text) = "" then m.sinopse.text = m.plotPainel
    m.temporadas = r.temporadas
    textos = []
    for each t in m.temporadas
        textos.Push(tx("Temporada") + " " + sv(t.numero))
    end for
    m.listaTemp = uiLista(m.top, 420, 600, 300, 5, 80)
    m.listaTemp.content = uiItensLista(textos)
    m.listaTemp.observeField("itemFocused", "aoTemporada")
    m.listaTemp.observeField("itemSelected", "aoTemporadaOk")
    m.listaEps = uiLista(m.top, 740, 600, 1100, 5, 80)
    m.listaEps.observeField("itemSelected", "aoEpisodio")
    atualizarBotoes()
    ' abre na temporada do próximo episódio
    p = proximoEpisodio()
    if p <> invalid then m.listaTemp.jumpToItem = p.t
    aoTemporada(invalid)
end sub

sub aoTemporada(ev as Object)
    i = m.listaTemp.itemFocused
    if i < 0 or i >= m.temporadas.Count() then return
    m.tempIdx = i
    desenharEpisodios()
    if idiomaEn() then
        t = chamar("TmdbTask", "temporada", { id: m.id, nome: m.nomeBruto, numero: sv(m.temporadas[i].numero) }, "aoTmdbTemp")
        marcarPedido("temp", t)
    end if
end sub

sub aoTmdbTemp(ev as Object)
    if not pedidoAtual("temp", ev) then return
    r = ev.getData()
    if r.ok = true then
        m.tmdbEps = r.eps
        desenharEpisodios()
    end if
end sub

sub aoTemporadaOk(ev as Object)
    m.listaEps.setFocus(true)
end sub

sub desenharEpisodios()
    if m.listaEps = invalid or m.tempIdx >= m.temporadas.Count() then return
    eps = m.temporadas[m.tempIdx].episodios
    textos = []
    for each e in eps
        nome = sv(e.title)
        if m.tmdbEps <> invalid and m.tmdbEps[sv(e.episode_num)] <> invalid and idiomaEn() then
            t = sv(m.tmdbEps[sv(e.episode_num)].titulo)
            if t <> "" then nome = t
        end if
        linha = "E" + Str(e.episode_num).Trim() + "  " + nome
        p = progressoDe("ep:" + sv(e.id))
        if p <> invalid and p.dur > 0 then
            if p.pos >= p.dur - 90 then
                linha = linha + "   ✔"
            else if p.pos > 20 then
                linha = linha + "   " + Str(Int(p.pos * 100 / p.dur)).Trim() + "%"
            end if
        end if
        textos.Push(linha)
    end for
    m.listaEps.content = uiItensLista(textos)
end sub

sub aoEpisodio(ev as Object)
    i = ev.getData()
    eps = m.temporadas[m.tempIdx].episodios
    if i < 0 or i >= eps.Count() then return
    p = progressoDe("ep:" + sv(eps[i].id))
    posicao = 0
    if p <> invalid and p.dur > 0 and p.pos > 20 and p.pos < p.dur - 90 then posicao = p.pos
    tocarEpisodio(m.tempIdx, i, posicao)
end sub

' Próximo episódio a assistir: o último começado (se não terminou) ou o seguinte ao último terminado.
function proximoEpisodio() as Dynamic
    if m.temporadas.Count() = 0 then return invalid
    melhor = invalid
    tmax = 0
    for t = 0 to m.temporadas.Count() - 1
        eps = m.temporadas[t].episodios
        for e = 0 to eps.Count() - 1
            p = progressoDe("ep:" + sv(eps[e].id))
            if p <> invalid and p.dur > 0 and p.t >= tmax then
                tmax = p.t
                melhor = { t: t, e: e, p: p }
            end if
        end for
    end for
    if melhor = invalid then return { t: 0, e: 0, pos: 0, rotulo: "Assistir" }
    p = melhor.p
    ep = m.temporadas[melhor.t].episodios[melhor.e]
    if p.pos < p.dur - 90 and p.pos > 20 then
        return { t: melhor.t, e: melhor.e, pos: p.pos, rotulo: "Continuar T" + sv(m.temporadas[melhor.t].numero) + " E" + Str(ep.episode_num).Trim() }
    end if
    ' terminou: vai para o próximo
    t = melhor.t
    e = melhor.e + 1
    if e >= m.temporadas[t].episodios.Count() then
        t = t + 1
        e = 0
    end if
    if t >= m.temporadas.Count() then return { t: 0, e: 0, pos: 0, rotulo: "Assistir de novo" }
    prox = m.temporadas[t].episodios[e]
    return { t: t, e: e, pos: 0, rotulo: "Assistir T" + sv(m.temporadas[t].numero) + " E" + Str(prox.episode_num).Trim() }
end function

sub tocarEpisodio(t as Integer, e as Integer, posicao as Integer)
    if m.adulto = true and parentalBloqueando() then
        m.epPendente = { t: t, e: e, pos: posicao }
        uiPin("Senha dos pais", pinOk)
        return
    end if
    s = sessaoLer()
    if s = invalid then return
    ' lista plana a partir deste episódio (para o "Próximo episódio")
    fila = []
    for tt = t to m.temporadas.Count() - 1
        eps = m.temporadas[tt].episodios
        ini = 0
        if tt = t then ini = e
        for ee = ini to eps.Count() - 1
            x = eps[ee]
            url = sv(x.url)
            if url = "" then
                ext = sv(x.container_extension)
                if ext = "" then ext = "mp4"
                url = urlStream(s, "series", sv(x.id), ext)
            end if
            nome = sv(x.title)
            fila.Push({ id: sv(x.id), url: url, titulo: "T" + sv(x.season) + " E" + Str(x.episode_num).Trim() + "  " + nome })
        end for
    end for
    uiAcao("abrir", { tela: "Player", args: {
        tipo: "episodio", titulo: m.titulo, pos: posicao, fila: fila, serie: m.id,
        reg: { tipo: "series", tid: m.id, nome: m.nomeBruto, capa: m.capaUrl, ext: "" }
    } })
end sub

function onKeyEvent(tecla as String, pressionou as Boolean) as Boolean
    if not pressionou then return false
    if m.listaTemp = invalid then return false
    if tecla = "down" and m.bt.isInFocusChain() then
        m.listaTemp.setFocus(true)
        return true
    else if tecla = "up" and (m.listaTemp.isInFocusChain() or m.listaEps.isInFocusChain()) then
        if (m.listaTemp.isInFocusChain() and m.listaTemp.itemFocused = 0) or (m.listaEps.isInFocusChain() and m.listaEps.itemFocused = 0) then
            m.bt.setFocus(true)
            return true
        end if
    else if tecla = "right" and m.listaTemp.isInFocusChain() then
        m.listaEps.setFocus(true)
        return true
    else if tecla = "left" and m.listaEps.isInFocusChain() then
        m.listaTemp.setFocus(true)
        return true
    end if
    return false
end function
