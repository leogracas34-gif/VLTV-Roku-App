' VLTV Play - Roku | Home: mesmo layout da Home da LG/Samsung (topo, banner de destaque, 3 cartões, rodapé).
' Medidas em 1920x1080, iguais às do style.css da LG. Imagens em pkg:/images/home_*.

sub iniciar()
    carregarI18n()
    m.slides = []
    m.pos = 0
    m.foco = "t0"
    m.ultimoTile = 0
    m.tmdbMap = {}
    m.logoAtual = ""
    m.dias = ["dom", "seg", "ter", "qua", "qui", "sex", "sáb"]

    ' Fundo da tela (brilhos roxo/vermelho, listras e vinheta, como na LG)
    uiNo(m.top, "Poster", { translation: [0, 0], width: 1920, height: 1080, uri: "pkg:/images/home_fundo.jpg", loadDisplayMode: "scaleToFill" })

    ' Topo: logo à esquerda; hora, data, aviso e engrenagem à direita
    uiNo(m.top, "Poster", { translation: [60, 90], width: 324, height: 60, uri: "pkg:/images/home_logo.png", loadDisplayMode: "scaleToFit" })
    m.hora = uiNo(m.top, "Label", { translation: [1120, 82], width: 640, height: 28, horizAlign: "right", vertAlign: "center", font: fonteHome(false, 24), color: uiSuave() })
    m.data = uiNo(m.top, "Label", { translation: [1120, 122], width: 640, height: 30, horizAlign: "right", vertAlign: "center", font: fonteHome(false, 26), color: uiSuave() })
    m.aviso = uiNo(m.top, "Label", { translation: [1120, 160], width: 640, height: 30, horizAlign: "right", vertAlign: "top", wrap: true, font: fonteHome(false, 22), color: "0xFFB020FF" })
    m.gearN = uiNo(m.top, "Poster", { translation: [1784, 82], width: 76, height: 76, uri: "pkg:/images/home_engrenagem.png", loadDisplayMode: "scaleToFit" })
    m.gearF = uiNo(m.top, "Poster", { translation: [1776, 74], width: 92, height: 92, uri: "pkg:/images/home_engrenagem_foco.png", loadDisplayMode: "scaleToFit", visible: false })

    montarBanner()
    montarTiles()
    montarRodape()
    montarCampanha()

    m.relogio = uiNo(m.top, "Timer", { repeat: true, duration: 15 })
    m.relogio.observeField("fire", "tique")
    m.relogio.control = "start"
    m.giro = uiNo(m.top, "Timer", { repeat: true, duration: 8 })
    m.giro.observeField("fire", "girar")

    aplicarVisual()
    tique()
    aplicarFoco()
    m.top.setFocus(true)
    t = chamar("ApiTask", "banner", { modo: "cache" }, "aoBannerCache")
end sub

sub retomar()
    ' voltou de outra tela: o controle parental trava de novo na Home
    m.global.parentalLiberado = false
    tique()
    m.giro.control = "start"
    aplicarFoco()
    m.top.setFocus(true)
end sub

sub encerrar()
    m.relogio.control = "stop"
    m.giro.control = "stop"
end sub

' ── Ajudantes ───────────────────────────────────────────────────────
function fonteHome(negrito as Boolean, tam as Integer) as Object
    f = CreateObject("roSGNode", "Font")
    if negrito then
        f.uri = "pkg:/images/LiberationSans-Bold.ttf"
    else
        f.uri = "pkg:/images/LiberationSans-Regular.ttf"
    end if
    f.size = tam
    return f
end function

function imagemHome(pai as Object, x as Integer, y as Integer, w as Integer, h as Integer, arq as String, modo as String) as Object
    return uiNo(pai, "Poster", { translation: [x, y], width: w, height: h, uri: "pkg:/images/" + arq, loadDisplayMode: modo })
end function

function medirHome(lbl as Object, tam as Integer) as Integer
    r = lbl.boundingRect()
    if r <> invalid then
        if r.width > 0 then return Int(r.width + 0.5)
    end if
    return Int(Len(sv(lbl.text)) * tam * 0.55)
end function

' ── Banner de destaque (1800x510 em 60,202) ─────────────────────────
sub montarBanner()
    m.bn = uiNo(m.top, "Group", { translation: [60, 202] })
    uiRet(m.bn, 0, 0, 1800, 510, "0x141416FF")

    ' área de dentro da borda (4px): corta o fundo para não vazar
    m.bnClip = uiNo(m.bn, "Group", { translation: [4, 4], clippingRect: [0, 0, 1792, 502] })
    m.bnFundo = uiNo(m.bnClip, "Poster", { translation: [0, 0], width: 1792, height: 502, loadDisplayMode: "scaleToFill" })
    m.bnFundo.observeField("loadStatus", "aoFundoCarregou")
    m.bnGrad = uiNo(m.bnClip, "Poster", { translation: [0, 0], width: 1792, height: 502, loadDisplayMode: "scaleToFill" })

    ' estado vazio (antes de chegar o primeiro destaque)
    m.bnVazio = uiNo(m.bn, "Group", {})
    uiRet(m.bnVazio, 4, 4, 1792, 502, "0x121214FF")
    imagemHome(m.bnVazio, 84, 205, 518, 97, "home_logo_vazio.png", "scaleToFit")

    m.bnConteudo = uiNo(m.bn, "Group", { visible: false })
    m.bnCapa = uiNo(m.bnConteudo, "Poster", { translation: [1416, 40], width: 310, height: 430, loadDisplayMode: "scaleToZoom" })
    m.bnLogo = uiNo(m.bnConteudo, "Poster", { translation: [84, 92], width: 720, height: 170, loadDisplayMode: "scaleToFit", visible: false })
    m.bnLogo.observeField("loadStatus", "aoLogoCarregou")
    m.bnTitulo = uiNo(m.bnConteudo, "Label", { translation: [84, 92], width: 1000, height: 170, wrap: true, maxLines: 2, vertAlign: "bottom", font: fonteHome(true, 68), color: uiTexto() })
    m.bnEstrela = imagemHome(m.bnConteudo, 84, 281, 28, 28, "home_estrela.png", "scaleToFit")
    m.bnMeta = uiNo(m.bnConteudo, "Label", { translation: [84, 278], width: 1000, height: 33, vertAlign: "center", font: fonteHome(false, 28), color: "0xFFFFFFD9" })

    ' botão ASSISTIR (pílula branca)
    m.bnTxt = uiNo(m.bnConteudo, "Label", { translation: [174, 340], height: 78, vertAlign: "center", font: fonteHome(true, 32), color: "0x0A0A0CFF", text: tx("ASSISTIR") })
    larg = 44 + 34 + 12 + medirHome(m.bnTxt, 32) + 44
    imagemHome(m.bnConteudo, 84, 340, 39, 78, "home_pilula_esq.png", "scaleToFill")
    imagemHome(m.bnConteudo, 84 + 39, 340, larg - 78, 78, "home_pilula_meio.png", "scaleToFill")
    imagemHome(m.bnConteudo, 84 + larg - 39, 340, 39, 78, "home_pilula_dir.png", "scaleToFill")
    imagemHome(m.bnConteudo, 128, 362, 34, 34, "home_play.png", "scaleToFit")
    ' o texto fica por cima da pílula
    m.bnConteudo.removeChild(m.bnTxt)
    m.bnConteudo.appendChild(m.bnTxt)

    m.bnPontos = uiNo(m.bnConteudo, "Group", { translation: [84, 468] })

    ' cantos arredondados e moldura de foco
    imagemHome(m.bn, 0, 0, 1800, 510, "home_cantos.png", "scaleToFit")
    m.bnFoco = uiNo(m.top, "Poster", { translation: [52, 194], width: 1816, height: 526, uri: "pkg:/images/home_banner_foco.png", loadDisplayMode: "scaleToFit", visible: false })
end sub

' ── Cartões: TV ao vivo, Filmes, Séries ─────────────────────────────
sub montarTiles()
    m.tiles = []
    nomes = ["live", "filmes", "series"]
    titulos = ["TV ao vivo", "Filmes", "Séries"]
    subs = ["Canais e programação", "Catálogo de filmes", "Temporadas e episódios"]
    for i = 0 to 2
        g = uiNo(m.top, "Group", { translation: [60 + i * 608, 738], scaleRotateCenter: [292, 80] })
        n = imagemHome(g, 0, 0, 584, 160, "home_tile_" + nomes[i] + ".png", "scaleToFit")
        f = imagemHome(g, -8, -8, 600, 176, "home_tile_" + nomes[i] + "_foco.png", "scaleToFit")
        f.visible = false
        uiNo(g, "Label", { translation: [40, 38], width: 504, height: 46, vertAlign: "center", font: fonteHome(true, 40), color: uiTexto(), text: tx(titulos[i]) })
        uiNo(g, "Label", { translation: [40, 91], width: 504, height: 29, vertAlign: "center", font: fonteHome(false, 25), color: "0xFFFFFFD1", text: tx(subs[i]) })
        m.tiles.Push({ grupo: g, normal: n, foco: f })
    end for
end sub

' ── Rodapé: Listas (esquerda) e Sair (direita) ──────────────────────
function criarBotao(texto as String, x as Integer, alinharDireita as Boolean) as Object
    lbl = uiNo(m.top, "Label", { height: 48, vertAlign: "center", horizAlign: "center", font: fonteHome(false, 24), color: uiSuave(), text: tx(texto) })
    w = 60 + medirHome(lbl, 24)
    if alinharDireita then x = x - w
    y = 972
    b = { x: x, w: w, lbl: lbl, n: [], f: []}
    b.n.Push(imagemHome(m.top, x, y, 24, 48, "home_btn_esq.png", "scaleToFill"))
    b.n.Push(imagemHome(m.top, x + 24, y, w - 48, 48, "home_btn_meio.png", "scaleToFill"))
    b.n.Push(imagemHome(m.top, x + w - 24, y, 24, 48, "home_btn_dir.png", "scaleToFill"))
    b.f.Push(imagemHome(m.top, x, y, 24, 48, "home_btn_foco_esq.png", "scaleToFill"))
    b.f.Push(imagemHome(m.top, x + 24, y, w - 48, 48, "home_btn_foco_meio.png", "scaleToFill"))
    b.f.Push(imagemHome(m.top, x + w - 24, y, 24, 48, "home_btn_foco_dir.png", "scaleToFill"))
    for each p in b.f
        p.visible = false
    end for
    lbl.translation = [x, y]
    lbl.width = w
    ' o texto fica por cima dos fundos
    m.top.removeChild(lbl)
    m.top.appendChild(lbl)
    return b
end function

sub montarRodape()
    m.btnListas = criarBotao("Listas", 60, false)
    m.btnSair = criarBotao("Sair", 1860, true)
end sub

sub pintarBotao(b as Object, ligado as Boolean)
    for each p in b.n
        p.visible = not ligado
    end for
    for each p in b.f
        p.visible = ligado
    end for
    if ligado then
        b.lbl.color = "0xFFFFFFFF"
    else
        b.lbl.color = uiSuave()
    end if
end sub

' ── Faixa de campanha (centro, no topo) ─────────────────────────────
sub montarCampanha()
    m.camp = uiNo(m.top, "Group", { translation: [960, 10], visible: false })
    m.campFundo = uiRet(m.camp, 0, 0, 100, 34, "0xFFFFFF12")
    m.campTopo = uiRet(m.camp, 0, 0, 100, 1, "0x2E2E34FF")
    m.campBase = uiRet(m.camp, 0, 33, 100, 1, "0x2E2E34FF")
    m.campDir = uiRet(m.camp, 99, 0, 1, 34, "0x2E2E34FF")
    m.campCor = uiRet(m.camp, 0, 0, 4, 34, "0xFF4B55FF")
    m.campTxt = uiNo(m.camp, "Label", { translation: [26, 0], height: 34, vertAlign: "center", font: fonteHome(true, 20), color: uiSuave() })
end sub

' ── Hora, data e avisos ─────────────────────────────────────────────
sub tique()
    m.hora.text = horaAgora()
    d = CreateObject("roDateTime")
    d.ToLocalTime()
    dia = d.GetDayOfMonth()
    mes = d.GetMonth()
    txt = m.dias[d.GetDayOfWeek()] + ", "
    if dia < 10 then txt = txt + "0"
    txt = txt + Str(dia).Trim() + "/"
    if mes < 10 then txt = txt + "0"
    txt = txt + Str(mes).Trim() + "/" + Str(d.GetYear()).Trim()
    m.data.text = txt
    avisos()
end sub

sub avisos()
    ' Aviso de vencimento/teste: texto laranja embaixo da data
    textos = licAvisos(m.global.lic, m.global.ehParceiro, iv(m.global.info.exp_date))
    linhas = 0
    if textos.Count() > 0 then
        t = ""
        for each x in textos
            if t <> "" then t = t + "  •  "
            t = t + tx(sv(x))
        end for
        m.aviso.text = t
        linhas = Int(Len(t) * 11 / 640) + 1
        if linhas > 3 then linhas = 3
        m.aviso.height = linhas * 29
        m.aviso.visible = true
    else
        m.aviso.text = ""
        m.aviso.visible = false
    end if
    ' o bloco do topo (hora, data, aviso) cresce e fica centralizado na altura de 120
    alt = 70
    if linhas > 0 then alt = 78 + linhas * 29
    if alt < 76 then alt = 76
    topo = 60 + Int((120 - alt) / 2)
    m.hora.translation = [1120, topo]
    m.data.translation = [1120, topo + 40]
    m.aviso.translation = [1120, topo + 78]
    m.gearN.translation = [1784, topo]
    m.gearF.translation = [1776, topo - 8]
    campanha()
end sub

sub campanha()
    v = m.global.visual
    vale = false
    t = ""
    cor = "0xFF4B55FF"
    if v <> invalid then
        if isAA(v) then
            if sv(v.aviso_texto) <> "" then
                vale = true
                ate = sv(v.aviso_ate)
                if Len(ate) = 10 then
                    hoje = CreateObject("roDateTime")
                    h = hoje.ToISOString()
                    if Left(h, 10) > ate then vale = false
                end if
                if vale then
                    t = sv(v.aviso_texto)
                    if sv(v.aviso_titulo) <> "" then t = sv(v.aviso_titulo) + " — " + t
                    c = sv(v.aviso_cor)
                    if Len(c) = 7 and Left(c, 1) = "#" then cor = "0x" + UCase(Mid(c, 2)) + "FF"
                end if
            end if
        end if
    end if
    if not vale then
        m.camp.visible = false
        return
    end if
    m.campTxt.text = t
    larg = medirHome(m.campTxt, 20) + 52
    if larg > 900 then larg = 900
    m.campTxt.width = larg - 48
    m.campFundo.width = larg
    m.campTopo.width = larg
    m.campBase.width = larg
    m.campDir.translation = [larg - 1, 0]
    m.campCor.color = cor
    m.camp.translation = [960 - Int(larg / 2), 10]
    m.camp.visible = true
end sub

sub aplicarVisual()
    avisos()
end sub

' ── Destaque ────────────────────────────────────────────────────────
sub aoBannerCache(ev as Object)
    chamarFim(ev)
    r = ev.getData()
    if r.ok = true then usarSlides(r.slides)
    chamar("ApiTask", "banner", { modo: "rede" }, "aoBannerRede")
end sub

sub aoBannerRede(ev as Object)
    chamarFim(ev)
    r = ev.getData()
    if r.ok = true and r.slides.Count() > 0 then usarSlides(r.slides)
end sub

sub usarSlides(recebidos as Object)
    ' cópia própria dos destaques (a tela acrescenta logo e fundo do TMDB neles)
    lista = []
    for each x in recebidos
        c = {}
        c.Append(x)
        lista.Push(c)
    end for
    m.slides = lista
    if m.pos >= lista.Count() then m.pos = 0
    mostrarSlide()
    m.giro.control = "start"
    ' logo e imagem de fundo do TMDB de cada destaque (guardados na TV depois da primeira vez)
    m.tmdbMap = {}
    for i = 0 to lista.Count() - 1
        s = lista[i]
        id = sv(s.id)
        if s.daVps = true then id = "vps" + id
        t = chamar("TmdbTask", "detalhe", { tipo: sv(s.tipo), id: id, nome: sv(s.nomeBruto) }, "aoTmdbSlide")
        m.tmdbMap[t.id] = i
    end for
end sub

sub aoTmdbSlide(ev as Object)
    n = ev.getRoSGNode()
    chamarFim(ev)
    r = ev.getData()
    i = m.tmdbMap[n.id]
    if i = invalid then return
    if r.ok <> true then return
    if i >= m.slides.Count() then return
    s = m.slides[i]
    mudou = false
    if sv(r.fundo) <> "" and sv(s.fundo) <> sv(r.fundo) then
        s.fundo = sv(r.fundo)
        mudou = true
    end if
    if sv(r.logo) <> "" and sv(s.logo) <> sv(r.logo) then
        s.logo = sv(r.logo)
        mudou = true
    end if
    if idiomaEn() and sv(r.titulo) <> "" then s.nomeEn = sv(r.titulo)
    if mudou and i = m.pos then mostrarSlide()
end sub

sub mostrarSlide()
    if m.slides.Count() = 0 then
        m.bnVazio.visible = true
        m.bnConteudo.visible = false
        m.bnFundo.uri = ""
        m.bnGrad.uri = ""
        return
    end if
    s = m.slides[m.pos]
    m.bnVazio.visible = false
    m.bnConteudo.visible = true
    ' fundo: imagem nítida do TMDB, ou a capa do servidor com o pôster ao lado
    if sv(s.fundo) <> "" then
        m.bnFundo.uri = sv(s.fundo)
        m.bnGrad.uri = "pkg:/images/home_grad_fundo.png"
        m.bnCapa.visible = false
    else
        m.bnFundo.uri = sv(s.capa)
        m.bnGrad.uri = "pkg:/images/home_grad_capa.png"
        m.bnCapa.uri = sv(s.capa)
        m.bnCapa.visible = true
    end if
    nome = sv(s.nome)
    if idiomaEn() and sv(s.nomeEn) <> "" then nome = sv(s.nomeEn)
    m.bnTitulo.text = nome
    logo = sv(s.logo)
    if logo <> "" then
        if m.logoAtual = logo then
            ' mesma imagem de antes: já está carregada, só mostra
            m.bnTitulo.visible = false
            m.bnLogo.visible = true
        else
            m.logoAtual = logo
            m.bnTitulo.visible = false
            m.bnLogo.visible = false
            m.bnLogo.uri = logo
        end if
    else
        m.logoAtual = ""
        m.bnLogo.visible = false
        m.bnLogo.uri = ""
        m.bnTitulo.visible = true
    end if
    ' a estrela é uma imagem (a fonte não tem esse caractere); o texto começa depois dela
    meta = ""
    esq = 84
    m.bnEstrela.visible = false
    if sv(s.nota) <> "" then
        meta = sv(s.nota)
        m.bnEstrela.visible = true
        esq = 84 + 36
    end if
    m.bnMeta.translation = [esq, 278]
    if sv(s.ano) <> "" then
        if meta <> "" then meta = meta + "   •   "
        meta = meta + sv(s.ano)
    end if
    if meta <> "" then meta = meta + "   •   "
    if sv(s.tipo) = "series" then
        meta = meta + tx("Série")
    else
        meta = meta + tx("Filme")
    end if
    m.bnMeta.text = meta
    desenharPontos()
end sub

' Pontos de baixo do banner: o do destaque atual é comprido e branco
sub desenharPontos()
    while m.bnPontos.getChildCount() > 0
        m.bnPontos.removeChildIndex(0)
    end while
    x = 0
    for i = 0 to m.slides.Count() - 1
        if i = m.pos then
            imagemHome(m.bnPontos, x, 0, 38, 14, "home_ponto_sel.png", "scaleToFit")
            x = x + 38 + 10
        else
            imagemHome(m.bnPontos, x, 0, 14, 14, "home_ponto.png", "scaleToFit")
            x = x + 14 + 10
        end if
    end for
end sub

' Imagem de fundo: cobre o banner, alinhada ao topo e centralizada (background-size: cover)
sub aoFundoCarregou()
    if m.bnFundo.loadStatus <> "ready" then return
    bw = m.bnFundo.bitmapWidth
    bh = m.bnFundo.bitmapHeight
    if bw <= 0 or bh <= 0 then return
    e = 1792 / bw
    e2 = 502 / bh
    if e2 > e then e = e2
    w = bw * e
    h = bh * e
    m.bnFundo.width = w
    m.bnFundo.height = h
    m.bnFundo.translation = [(1792 - w) / 2, 0]
end sub

' Logo do TMDB: tamanho natural, no máximo 720x170, encostado embaixo e à esquerda
sub aoLogoCarregou()
    st = m.bnLogo.loadStatus
    if st = "failed" then
        m.bnLogo.visible = false
        m.bnTitulo.visible = true
        return
    end if
    if st <> "ready" then return
    bw = m.bnLogo.bitmapWidth
    bh = m.bnLogo.bitmapHeight
    if bw <= 0 or bh <= 0 then return
    e = 1.0
    if bw * e > 720 then e = 720 / bw
    if bh * e > 170 then e = 170 / bh
    w = Int(bw * e)
    h = Int(bh * e)
    m.bnLogo.width = w
    m.bnLogo.height = h
    m.bnLogo.translation = [84, 92 + 170 - h]
    m.bnLogo.visible = true
    m.bnTitulo.visible = false
end sub

sub girar()
    if m.slides.Count() < 2 then return
    mover(1)
end sub

sub mover(passo as Integer)
    n = m.slides.Count()
    if n < 2 then return
    m.pos = (m.pos + passo + n) mod n
    mostrarSlide()
    m.giro.control = "start"
end sub

' ── Foco ────────────────────────────────────────────────────────────
sub aplicarFoco()
    f = m.foco
    m.bnFoco.visible = (f = "banner")
    m.gearN.visible = (f <> "gear")
    m.gearF.visible = (f = "gear")
    for i = 0 to 2
        ligado = (f = "t" + Str(i).Trim())
        m.tiles[i].normal.visible = not ligado
        m.tiles[i].foco.visible = ligado
        if ligado then
            m.tiles[i].grupo.scale = [1.03, 1.03]
        else
            m.tiles[i].grupo.scale = [1, 1]
        end if
    end for
    pintarBotao(m.btnListas, f = "listas")
    pintarBotao(m.btnSair, f = "sair")
end sub

sub irPara(alvo as String)
    m.foco = alvo
    if Left(alvo, 1) = "t" and Len(alvo) = 2 then m.ultimoTile = Int(Val(Mid(alvo, 2)))
    aplicarFoco()
end sub

function irAoTile() as String
    return "t" + Str(m.ultimoTile).Trim()
end function

sub abrirTile(i as Integer)
    if i = 0 then
        uiAcao("abrir", { tela: "Live", args: {} })
    else if i = 1 then
        uiAcao("abrir", { tela: "Catalogo", args: { tipo: "filmes" } })
    else
        uiAcao("abrir", { tela: "Catalogo", args: { tipo: "series" } })
    end if
end sub

sub aoDestaque()
    if m.slides.Count() = 0 then return
    s = m.slides[m.pos]
    uiAcao("abrir", { tela: "Detalhe", args: { tipo: sv(s.tipo), id: sv(s.id), nome: sv(s.nomeBruto), capa: sv(s.capa), ext: "", cat: "" } })
end sub

sub sairConta()
    uiAcao("sair", invalid)
end sub

function onKeyEvent(tecla as String, pressionou as Boolean) as Boolean
    if not pressionou then return false
    f = m.foco
    temBanner = (m.slides.Count() > 0)

    if tecla = "options" then
        uiAcao("abrir", { tela: "Ajustes", args: {} })
        return true
    end if

    if tecla = "OK" then
        if f = "gear" then
            uiAcao("abrir", { tela: "Ajustes", args: {} })
        else if f = "banner" then
            aoDestaque()
        else if f = "listas" then
            uiAcao("abrir", { tela: "Listas", args: {} })
        else if f = "sair" then
            uiConfirmar("Deseja sair?", "A lista que está em uso será removida desta TV.", "Sair", "Cancelar", sairConta)
        else
            abrirTile(m.ultimoTile)
        end if
        return true
    end if

    if Left(f, 1) = "t" and Len(f) = 2 then
        if tecla = "left" then
            if m.ultimoTile > 0 then irPara("t" + Str(m.ultimoTile - 1).Trim())
            return true
        else if tecla = "right" then
            if m.ultimoTile < 2 then irPara("t" + Str(m.ultimoTile + 1).Trim())
            return true
        else if tecla = "up" then
            if temBanner then irPara("banner") else irPara("gear")
            return true
        else if tecla = "down" then
            irPara("listas")
            return true
        end if
    else if f = "banner" then
        if tecla = "left" then
            mover(-1)
            return true
        else if tecla = "right" then
            mover(1)
            return true
        else if tecla = "up" then
            irPara("gear")
            return true
        else if tecla = "down" then
            irPara(irAoTile())
            return true
        end if
    else if f = "gear" then
        if tecla = "down" then
            if temBanner then irPara("banner") else irPara(irAoTile())
            return true
        end if
        if tecla = "left" or tecla = "right" or tecla = "up" then return true
    else if f = "listas" then
        if tecla = "up" then
            irPara(irAoTile())
            return true
        else if tecla = "right" then
            irPara("sair")
            return true
        else if tecla = "left" or tecla = "down" then
            return true
        end if
    else if f = "sair" then
        if tecla = "up" then
            irPara(irAoTile())
            return true
        else if tecla = "left" then
            irPara("listas")
            return true
        else if tecla = "right" or tecla = "down" then
            return true
        end if
    end if
    return false
end function
