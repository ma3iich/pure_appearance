(function () {
    'use strict';

    var RES = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'pure_appearance';

    function post(name, data) {
        return fetch('https://' + RES + '/' + name, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data === undefined ? {} : data)
        }).then(function (r) { return r.json(); }).catch(function () { return null; });
    }

    function $(id) { return document.getElementById(id); }
    function el(tag, cls, html) {
        var e = document.createElement(tag);
        if (cls) e.className = cls;
        if (html != null) e.innerHTML = html;
        return e;
    }
    function on(e, fn) { e.addEventListener('click', fn); return e; }
    function copy(o) { return JSON.parse(JSON.stringify(o)); }
    function same(a, b) { return JSON.stringify(a) === JSON.stringify(b); }
    function esc(s) { return String(s).replace(/[&<>"']/g, function (c) { return '&#' + c.charCodeAt(0) + ';'; }); }
    function fill(str, vars) {
        return String(str).replace(/\{(\w+)\}/g, function (m, k) { return vars && vars[k] != null ? vars[k] : m; });
    }
    function throttle(fn, ms) {
        var timer = null, last = null;
        return function (v) {
            last = v;
            if (timer) return;
            timer = setTimeout(function () { timer = null; fn(last); }, ms);
        };
    }

    var ICONS = {
        heritage: '<circle cx="8" cy="8" r="3"/><circle cx="16" cy="8" r="3"/><path d="M3 20c0-3 2.4-5 5-5s5 2 5 5M11 20c0-3 2.4-5 5-5s5 2 5 5"/>',
        face: '<path d="M12 3C8 3 5.5 6 5.5 10.5S8.5 20 12 20s6.5-5 6.5-9.5S16 3 12 3z"/><path d="M9.5 10.5h.01M14.5 10.5h.01M10 15c1.2.8 2.8.8 4 0"/>',
        skin: '<path d="M12 3s6 6.5 6 11a6 6 0 0 1-12 0c0-4.5 6-11 6-11z"/><path d="M9.5 14.5A2.5 2.5 0 0 0 12 17"/>',
        eyes: '<path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12z"/><circle cx="12" cy="12" r="3"/>',
        hair: '<circle cx="6" cy="6" r="3"/><circle cx="6" cy="18" r="3"/><path d="M8.6 7.6 20 18M8.6 16.4 20 6"/>',
        facialhair: '<path d="M5 8c0 6.5 3 12 7 12s7-5.5 7-12"/><path d="M8 13c1.5-1 2.5-1 4 0 1.5-1 2.5-1 4 0"/><path d="M5 8V4M19 8V4"/>',
        makeup: '<path d="M9 21h6v-8H9z"/><path d="M10 13V7l4-3v9"/><path d="M7.5 21h9"/>',
        ZONE_HEAD: '<circle cx="12" cy="9" r="5"/><path d="M7.5 20c0-2.6 2-4.6 4.5-4.6s4.5 2 4.5 4.6"/>',
        ZONE_TORSO: '<path d="M7 4 3 7l2 4 2-1v10h10V10l2 1 2-4-4-3c-1 1.5-3 2.5-5 2.5S8 5.5 7 4z"/>',
        ZONE_LEFT_ARM: '<path d="M20 18c-2-6-4-10-8-12-2-1-4 0-4 2s2 3 4 3c-2 0-5 1-6 4"/>',
        ZONE_RIGHT_ARM: '<path d="M4 18c2-6 4-10 8-12 2-1 4 0 4 2s-2 3-4 3c2 0 5 1 6 4"/>',
        ZONE_LEFT_LEG: '<path d="M10 3h5v8l-1 9h-4l1-9z"/>',
        ZONE_RIGHT_LEG: '<path d="M9 3h5l-1 8 1 9h-4l-1-9z"/>',
        worn: '<path d="M5 12.5 9.5 17 19 7"/>',
        clothes: '<path d="M7 4 3 7l2 4 2-1v10h10V10l2 1 2-4-4-3c-1 1.5-3 2.5-5 2.5S8 5.5 7 4z"/>',
        tattoos: '<path d="M4 20l5-5M13.5 4.5l6 6-8.5 8.5-6-6z"/><path d="M11 7l6 6"/>',
        needle: '<path d="M4 20l5-5M13.5 4.5l6 6-8.5 8.5-6-6z"/><path d="M11 7l6 6"/>',
        search: '<circle cx="11" cy="11" r="6.5"/><path d="M16 16l4.5 4.5"/>',
        left: '<path d="M15 5l-7 7 7 7"/>',
        right: '<path d="M9 5l7 7-7 7"/>'
    };
    function icon(n) { return '<svg viewBox="0 0 24 24">' + (ICONS[n] || '') + '</svg>'; }

    var FACE_GROUPS = [
        ['nose', ['noseWidth', 'nosePeakHigh', 'nosePeakSize', 'noseBoneHigh', 'nosePeakLowering', 'noseBoneTwist']],
        ['eyebrows', ['eyeBrownHigh', 'eyeBrownForward']],
        ['cheekbones', ['cheeksBoneHigh', 'cheeksBoneWidth']],
        ['cheeks', ['cheeksWidth']],
        ['eyes', ['eyesOpening']],
        ['lips', ['lipsThickness']],
        ['jaw', ['jawBoneWidth', 'jawBoneBackSize']],
        ['chin', ['chinBoneLowering', 'chinBoneLenght', 'chinBoneSize', 'chinHole']],
        ['neck', ['neckThickness']]
    ];
    var SKIN = ['blemishes', 'ageing', 'complexion', 'sunDamage', 'moleAndFreckles', 'bodyBlemishes'];
    var FACIAL = ['beard', 'eyebrows', 'chestHair'];
    var MAKEUP = ['makeUp', 'blush', 'lipstick'];
    var BARBER = ['hair'].concat(FACIAL, MAKEUP);
    var ZONES = ['ZONE_HEAD', 'ZONE_TORSO', 'ZONE_LEFT_ARM', 'ZONE_RIGHT_ARM', 'ZONE_LEFT_LEG', 'ZONE_RIGHT_LEG'];
    var CAMERA = {
        heritage: 'face', face: 'face', skin: 'face', eyes: 'face', hair: 'face', facialhair: 'face', makeup: 'face',
        ZONE_HEAD: 'face', ZONE_TORSO: 'chest', ZONE_LEFT_ARM: 'chest', ZONE_RIGHT_ARM: 'chest',
        ZONE_LEFT_LEG: 'body', ZONE_RIGHT_LEG: 'body', worn: 'body', clothes: 'body', tattoos: 'chest'
    };
    var EYE_RGB = ['#3f7a3b', '#1f8f62', '#7fb3d9', '#2c6aa8', '#9a6a3a', '#5a3a22', '#8a6a2e', '#4a4f55', '#9aa1a8', '#d68aa3',
        '#d9c23a', '#7b4fa8', '#121212', '#6d6d6d', '#d9822b', '#9ad93a', '#3ad9c9', '#c9302c', '#3a8ad9', '#e8e8e8', '#b83a3a',
        '#6aa83a', '#d95c2b', '#7ad93a', '#c9a23a', '#e8d23a', '#e8e8e8', '#d92b2b', '#a8b83a', '#3ad97a', '#b8c2c9', '#8a9a6a'];
    var COLLECTIONS = {
        multiplayer_overlays: 'GTA Online', mpairraces_overlays: 'Air Races', mpbeach_overlays: 'Beach Bum',
        mpbiker_overlays: 'Bikers', mpbusiness_overlays: 'Business', mpchristmas2_overlays: 'Festive Surprise',
        mpchristmas2017_overlays: 'Doomsday', mpchristmas2018_overlays: 'Arena War', mpchristmas3_overlays: 'Drug Wars',
        mpgunrunning_overlays: 'Gunrunning', mphipster_overlays: 'Hipster', mpimportexport_overlays: 'Import/Export',
        mplowrider_overlays: 'Lowriders', mplowrider2_overlays: 'Lowriders: Custom Classics', mpluxe_overlays: 'Ill-Gotten Gains',
        mpluxe2_overlays: 'Ill-Gotten Gains 2', mpsmuggler_overlays: "Smuggler's Run", mpstunt_overlays: 'Cunning Stunts',
        mpvinewood_overlays: 'Diamond Casino', mpheist3_overlays: 'Casino Heist', mpheist4_overlays: 'Cayo Perico',
        mpsecurity_overlays: 'The Contract', mptuner_overlays: 'Tuners', mpsum2_overlays: 'Criminal Enterprises',
        mp2023_01_overlays: 'San Andreas Mercenaries', mp2023_02_overlays: 'The Chop Shop',
        mp2024_01_overlays: 'Bottom Dollar Bounties', mp2024_02_overlays: 'Agents of Sabotage', mpvalentines_overlays: "Valentine's Day",
        mpindependence_overlays: 'Independence Day', mpheist_overlays: 'Heists', mpapartment_overlays: 'Executives'
    };
    function collectionName(c) {
        c = String(c || '').toLowerCase();
        if (COLLECTIONS[c]) return COLLECTIONS[c];
        return c.replace(/^mp_?/, '').replace(/_overlays$/, '').replace(/_/g, ' ');
    }

    var S = null;

    function t(path, vars) {
        var v = S && S.p.locale;
        path.split('.').forEach(function (k) { v = v != null ? v[k] : null; });
        return v == null ? path : fill(v, vars);
    }
    function money(n) {
        var lang = (S && S.p.lang) || 'en';
        var s = Math.round(n || 0).toLocaleString(lang === 'fr' ? 'fr-FR' : 'en-US').replace(/ | /g, ' ');
        return t('common.money', { n: s });
    }

    function open(p) {
        p.data = p.data || {};
        p.data.tattoos = p.data.tattoos && !Array.isArray(p.data.tattoos) ? p.data.tattoos : {};
        S = {
            p: p,
            data: copy(p.data),
            origin: copy(p.data),
            section: (p.sections || [])[0],
            tab: {},
            parent: 1,
            part: 'face',
            sub: { facialhair: 'beard', makeup: 'makeUp', tattoos: 'ZONE_TORSO', clothes: null },
            search: '',
            cart: {},
            removals: {},
            hidden: false,
            camera: null,
            hairTextures: p.hair && p.hair.textures != null ? p.hair.textures : 1,
            busy: false
        };
        applyUi(p.ui || {});
        S.keys = p.keys || {};
        $('app').classList.remove('hidden');
        $('keys').classList.remove('hidden');
        closeModal();
        notice(null);
        render();
        camera(CAMERA[S.section] || 'face');
    }

    var COLOR_VARS = { accent: '--accent', text: '--text', textSoft: '--text-2', box: '--slot-bg', boxHover: '--slot-hover',
        boxActive: '--slot-active', outline: '--outline' };
    function applyUi(ui) {
        var root = document.documentElement.style;
        var colors = ui.colors || {};
        Object.keys(colors).forEach(function (k) { if (COLOR_VARS[k]) root.setProperty(COLOR_VARS[k], colors[k]); });
        if (ui.font) root.setProperty('--font', "'" + ui.font + "', 'Poppins', Roboto, sans-serif");
        document.body.style.zoom = Number(ui.scale) > 0 ? Number(ui.scale) : 1;
        document.body.classList.toggle('right', ui.side === 'right');
        var logo = $('logo');
        if (ui.logo) { logo.src = ui.logo; logo.classList.remove('hidden'); } else { logo.classList.add('hidden'); }
    }
    function keyOf(name, fallback) { return String((S && S.keys && S.keys[name]) || fallback).toUpperCase(); }

    function close() {
        S = null;
        dragging = false;
        $('app').classList.add('hidden');
        $('keys').classList.add('hidden');
        closeModal();
        $('content').innerHTML = '';
        $('sections').innerHTML = '';
    }

    window.addEventListener('message', function (e) {
        var d = e.data || {};
        if (d.action === 'open' && d.data) open(d.data);
        else if (d.action === 'close') close();
    });

    var sendFace = throttle(function () { post('pa_face_feature', S.data.faceFeatures); }, 60);
    var sendOverlays = throttle(function () { post('pa_head_overlay', S.data.headOverlays); }, 60);
    var sendBlend = throttle(function () { post('pa_head_blend', S.data.headBlend); }, 60);

    function sendHair() {
        return post('pa_hair', S.data.hair).then(function (r) {
            if (S && r && r.textures != null) { S.hairTextures = r.textures; }
        });
    }

    function camera(name) {
        if (!S || S.camera === name) return;
        S.camera = name;
        post('pa_camera', name);
        renderKeys();
    }

    function previewTattoos() {
        post('pa_tattoos', { tattoos: tattooSet() });
    }

    function tattooSet() {
        var set = {};
        ZONES.forEach(function (z) {
            var list = [];
            (S.data.tattoos[z] || []).forEach(function (tt) { if (!S.removals[tt.name]) list.push(tt); });
            Object.keys(S.cart).forEach(function (n) { if (S.cart[n].zone === z) list.push(S.cart[n]); });
            if (list.length) set[z] = list;
        });
        return set;
    }

    function finalAppearance() {
        var a = copy(S.data);
        if (S.p.mode === 'tattoo' || S.p.mode === 'creation') a.tattoos = tattooSet();
        return a;
    }

    function overlayChanged(k) {
        return !same((S.data.headOverlays || {})[k], (S.origin.headOverlays || {})[k]);
    }
    function barberChanges() {
        return BARBER.filter(function (k) {
            return k === 'hair' ? !same(S.data.hair, S.origin.hair) : overlayChanged(k);
        }).length;
    }
    function surgeonChanged() {
        return !same(S.data.headBlend, S.origin.headBlend) || !same(S.data.faceFeatures, S.origin.faceFeatures)
            || S.data.eyeColor !== S.origin.eyeColor || SKIN.some(overlayChanged);
    }
    function cartList() { return Object.keys(S.cart).map(function (n) { return S.cart[n]; }); }
    function removalCount() { return Object.keys(S.removals).filter(function (n) { return S.removals[n]; }).length; }

    function bill() {
        var pr = S.p.prices || {};
        if (S.p.mode === 'barber') {
            var n = barberChanges();
            return { total: n * (pr.category || 0), changed: n > 0,
                label: n === 0 ? t('footer.nothingChanged') : n === 1 ? t('footer.category') : t('footer.categories', { n: n }) };
        }
        if (S.p.mode === 'surgeon') {
            var c = surgeonChanged();
            return { total: c ? (pr.surgeon || 0) : 0, changed: c, label: c ? t('footer.flatFee') : t('footer.nothingChanged') };
        }
        if (S.p.mode === 'tattoo') {
            var items = cartList(), rem = removalCount();
            var total = items.reduce(function (s, tt) { return s + (tt.price || 0); }, 0) + rem * (pr.tattooRemove || 0);
            var parts = [];
            if (items.length) parts.push(items.length === 1 ? t('footer.tattoo') : t('footer.tattoos', { n: items.length }));
            if (rem) parts.push(t('footer.removals', { n: rem }));
            return { total: total, changed: items.length + rem > 0, label: parts.length ? parts.join(' · ') : t('footer.nothingChanged') };
        }
        return { total: 0, changed: true, label: t('footer.creation') };
    }

    function block(title, right) {
        var b = el('div', 'block');
        if (title) b.appendChild(el('div', 'block-title', esc(title) + (right ? '<em>' + esc(right) + '</em>' : '')));
        return b;
    }
    function chips(list, active, pick) {
        var c = el('div', 'chips');
        list.forEach(function (x) {
            c.appendChild(on(el('button', 'chip' + (x[0] === active ? ' active' : ''), esc(x[1])), function () { pick(x[0]); }));
        });
        return c;
    }
    function tabs(nbBase, nbNew) {
        var box = $('tabs');
        box.innerHTML = '';
        if (!nbNew) { S.tab[S.section] = 'base'; return 'base'; }
        var cur = S.tab[S.section] || 'base';
        [['base', nbBase], ['new', nbNew]].forEach(function (x) {
            box.appendChild(on(el('button', 'tab' + (cur === x[0] ? ' active' : ''), esc(t('tabs.' + x[0])) + ' <em>' + x[1] + '</em>'), function () {
                S.tab[S.section] = x[0];
                renderPanel(true);
            }));
        });
        return cur;
    }
    function slider(label, value, min, max, step, show, change, centered) {
        var s = el('div', 'slider');
        var line = el('div', 'line', '<span>' + esc(label) + '</span><b></b>');
        var input = el('input');
        input.type = 'range'; input.min = min; input.max = max; input.step = step; input.value = value;
        function paint() {
            var v = Number(input.value), pct = (v - min) / (max - min) * 100;
            var a = centered ? Math.min(50, pct) : 0, b = centered ? Math.max(50, pct) : pct;
            input.style.setProperty('--fill', 'linear-gradient(90deg, var(--track) ' + a + '%, rgba(255,255,255,0.85) ' + a + '%, rgba(255,255,255,0.85) ' + b + '%, var(--track) ' + b + '%)');
            line.querySelector('b').textContent = show(v);
        }
        input.addEventListener('input', function () { paint(); change(Number(input.value)); });
        input.addEventListener('dblclick', function () {
            if (!centered) return;
            input.value = 0; paint(); change(0);
        });
        paint();
        s.appendChild(line);
        s.appendChild(input);
        return s;
    }
    function stepper(text, prev, next) {
        var s = el('div', 'stepper');
        s.appendChild(on(el('button', '', icon('left')), prev));
        s.appendChild(el('div', 'value', text));
        s.appendChild(on(el('button', '', icon('right')), next));
        return s;
    }
    function palette(colors, active, pick) {
        var p = el('div', 'palette');
        (colors || []).forEach(function (c, i) {
            var b = el('button', 'swatch' + (i === active ? ' active' : ''));
            b.style.background = 'rgb(' + c[0] + ',' + c[1] + ',' + c[2] + ')';
            p.appendChild(on(b, function () { pick(i); }));
        });
        return p;
    }
    function tile(cls, inner, active, pick) {
        return on(el('button', 'tile ' + (cls || '') + (active ? ' active' : ''), inner), pick);
    }
    function imgTile(src, num, active, pick, extra) {
        var b = tile(extra, src ? '<span class="num">' + num + '</span>' : '', active, pick);
        if (src) {
            var img = new Image();
            img.alt = '';
            img.loading = 'lazy';
            img.onerror = function () {
                img.remove();
                var label = b.querySelector('.num');
                if (label) label.remove();
                b.insertAdjacentHTML('afterbegin', '<span class="big">' + num + '</span>');
            };
            img.src = src;
            b.insertBefore(img, b.firstChild);
        } else {
            b.insertAdjacentHTML('afterbegin', '<span class="big">' + num + '</span>');
        }
        return b;
    }
    var pictures = {};
    function withPicture(src, ready) {
        if (pictures[src] === false) return;
        var img = new Image();
        img.alt = '';
        img.onload = function () { pictures[src] = true; ready(img); };
        img.onerror = function () { pictures[src] = false; };
        img.src = src;
    }
    function pictureTile(src, num, active, pick) {
        var b = tile('', '<span class="big">' + num + '</span>', active, pick);
        withPicture(src, function (img) {
            var big = b.querySelector('.big');
            if (big) big.remove();
            b.insertAdjacentHTML('afterbegin', '<span class="num">' + num + '</span>');
            b.insertBefore(img, b.firstChild);
        });
        return b;
    }
    function overlayPicture(k, n) { return 'images/' + S.p.sex + '/' + k + '/' + n + '.webp'; }
    function tattooPicture(tt) { return 'images/tattoos/' + encodeURIComponent(tt.name) + '.webp'; }

    function keepScroll(fn) {
        var c = $('content'), top = c.scrollTop;
        fn();
        c.scrollTop = top;
    }

    var PORTRAIT_NAMES = function (i) {
        if (i <= 20) return 'male_' + i;
        if (i <= 41) return 'female_' + (i - 21);
        if (i <= 44) return 'special_male_' + (i - 42);
        return 'special_female_' + (i - 45);
    };
    function nativePortrait(i) { return fill(S.p.heritage.portrait, { name: PORTRAIT_NAMES(i) }); }

    function pageHeritage(c) {
        var h = S.p.heritage, hb = S.data.headBlend;
        var addons = h.addons || [];
        var skinPart = S.part === 'skin';
        var tab = skinPart ? (S.tab.heritage = 'base') : tabs(h.natives, addons.length);
        if (skinPart) $('tabs').innerHTML = '';
        $('panel-title').textContent = t('sections.heritage');
        $('panel-sub').textContent = skinPart ? '' : tab === 'new' ? t('heritage.newFaces') : t('heritage.gameFaces');

        if (S.p.canChangeSex) {
            var bs = block(t('heritage.sex'));
            bs.appendChild(chips([['m', t('heritage.male')], ['f', t('heritage.female')]], S.p.sex, changeSex));
            $('controls').appendChild(bs);
        }

        var top = block(null);
        var row = el('div', 'chips');
        row.appendChild(chips([[1, t('heritage.parent1')], [2, t('heritage.parent2')]], S.parent, function (v) { S.parent = v; renderPanel(true); }));
        top.appendChild(row);
        top.appendChild(chips([['face', t('heritage.face')], ['skin', t('heritage.skin')]], S.part, function (v) { S.part = v; renderPanel(true); }));
        $('controls').appendChild(top);
        var b = block(null);

        var key = (skinPart ? 'skin' : 'shape') + (S.parent === 1 ? 'First' : 'Second');
        var g = el('div', 'grid');
        function pick(id, native) {
            hb[key] = id;
            if (!skinPart && native) hb['skin' + (S.parent === 1 ? 'First' : 'Second')] = id;
            sendBlend();
            keepScroll(function () { renderPanel(false); });
            renderFooter();
        }
        if (tab === 'new' && !skinPart) {
            addons.forEach(function (a) {
                var src = a.img;
                var tl = imgTile(src, a.id, hb[key] === a.id, function () { pick(a.id, false); }, 'portrait');
                g.appendChild(tl);
            });
        } else {
            for (var i = 0; i < h.natives; i++) {
                (function (id) {
                    g.appendChild(imgTile(nativePortrait(id), id, hb[key] === id, function () { pick(id, true); }, 'portrait'));
                })(i);
            }
        }
        b.appendChild(g);
        c.appendChild(b);

        var m = block(t('heritage.mix'));
        var sl = el('div', 'sliders');
        function share(v) { return t('heritage.share', { pct: Math.round((1 - v) * 100) }); }
        sl.appendChild(slider(t('heritage.resemblance'), hb.shapeMix || 0, 0, 1, 0.05, share, function (v) { hb.shapeMix = v; sendBlend(); renderFooter(); }));
        sl.appendChild(slider(t('heritage.skinTone'), hb.skinMix || 0, 0, 1, 0.05, share, function (v) { hb.skinMix = v; sendBlend(); renderFooter(); }));
        m.appendChild(sl);
        c.appendChild(m);
    }

    function changeSex(sex) {
        if (!S || sex === S.p.sex || S.busy) return;
        S.busy = true;
        post('pa_model', { model: S.p.models[sex] }).then(function (r) {
            S.busy = false;
            if (!S || !r) return;
            S.p.sex = sex;
            if (r.heritage) S.p.heritage = r.heritage;
            if (r.hair) S.p.hair = r.hair;
            if (r.clothes) S.p.clothes = r.clothes;
            if (r.data) { S.data = copy(r.data); S.data.tattoos = S.data.tattoos || {}; }
            S.hairTextures = r.hair && r.hair.textures != null ? r.hair.textures : 1;
            render();
        });
    }

    function pageFace(c) {
        $('tabs').innerHTML = '';
        var ff = S.data.faceFeatures;
        var n = FACE_GROUPS.reduce(function (s, g) { return s + g[1].length; }, 0);
        $('panel-title').textContent = t('sections.face');
        $('panel-sub').textContent = t('face.count', { n: n });
        FACE_GROUPS.forEach(function (g) {
            var b = block(t('face.groups.' + g[0]));
            var sl = el('div', 'sliders');
            g[1].forEach(function (k) {
                sl.appendChild(slider(t('face.features.' + k), ff[k] || 0, -1, 1, 0.05, function (v) { return v.toFixed(2); },
                    function (v) { ff[k] = v; sendFace(); renderFooter(); }, true));
            });
            b.appendChild(sl);
            c.appendChild(b);
        });
    }

    function overlay(k) {
        var ho = S.data.headOverlays;
        if (!ho[k]) ho[k] = { style: 0, opacity: 0, color: 0, secondColor: 0 };
        return ho[k];
    }
    function overlayOff(o) { return !o.opacity; }

    function pageSkin(c) {
        $('tabs').innerHTML = '';
        $('panel-title').textContent = t('sections.skin');
        $('panel-sub').textContent = t('common.gameList');
        SKIN.forEach(function (k) {
            var count = S.p.overlays[k] || 0;
            if (!count) return;
            var o = overlay(k);
            var b = block(t('overlays.' + k), t('common.styles', { n: count }));
            var text = overlayOff(o) ? esc(t('common.none')) : esc(t('common.style')) + ' ' + (o.style + 1) + ' <em>/ ' + count + '</em>';
            b.appendChild(stepper(text, function () { stepOverlay(k, -1, count); }, function () { stepOverlay(k, 1, count); }));
            if (!overlayOff(o)) {
                b.appendChild(slider(t('common.opacity'), o.opacity, 0, 1, 0.05, function (v) { return Math.round(v * 100) + ' %'; },
                    function (v) { o.opacity = v; if (v > 0) o.lastOpacity = v; sendOverlays(); renderFooter(); }));
            }
            c.appendChild(b);
        });
    }
    function stepOverlay(k, dir, count) {
        var o = overlay(k);
        var pos = overlayOff(o) ? -1 : o.style;
        pos += dir;
        if (pos < -1) pos = count - 1;
        if (pos > count - 1) pos = -1;
        setOverlay(k, pos);
        keepScroll(function () { renderPanel(false); });
    }
    function setOverlay(k, pos) {
        var o = overlay(k);
        if (pos < 0) { if (o.opacity) o.lastOpacity = o.opacity; o.opacity = 0; }
        else { o.style = pos; if (!o.opacity) o.opacity = o.lastOpacity || 1; }
        sendOverlays();
        renderFooter();
        renderSections();
    }

    function pageEyes(c) {
        $('tabs').innerHTML = '';
        var n = S.p.eyeColors || 32;
        $('panel-title').textContent = t('sections.eyes');
        $('panel-sub').textContent = t('common.eyeCount', { n: n });
        var b = block(t('common.eyeColor'));
        var g = el('div', 'eyes');
        var names = (S.p.locale.eyeColors || []);
        for (var i = 0; i < n; i++) {
            (function (id) {
                var e = el('button', 'eye' + (S.data.eyeColor === id ? ' active' : ''), '<i style="background:' + (EYE_RGB[id] || '#777') + '"></i>' + esc(names[id] || String(id + 1)));
                g.appendChild(on(e, function () {
                    S.data.eyeColor = id;
                    post('pa_eye_color', id);
                    keepScroll(function () { renderPanel(false); });
                    renderFooter();
                }));
            })(i);
        }
        b.appendChild(g);
        c.appendChild(b);
    }

    function pageHair(c) {
        var items = (S.p.hair && S.p.hair.items) || [];
        var base = items.filter(function (i) { return !i.addon; });
        var added = items.filter(function (i) { return i.addon; });
        var tab = tabs(base.length, added.length);
        var list = tab === 'new' ? added : base;
        var hair = S.data.hair;
        $('panel-title').textContent = t('sections.hair');
        $('panel-sub').textContent = tab === 'new' ? t('common.newHair') : t('common.gameHair');

        var b = block(null);
        var g = el('div', 'grid');
        list.forEach(function (it, pos) {
            var num = tab === 'new' ? pos + 1 : pos;
            var active = hair.style === it.d;
            var tl;
            if (tab !== 'new' && it.d === 0 && !it.img) {
                tl = tile('', '<span class="word">' + esc(t('common.shaved')) + '</span><span class="num">0</span>', active, pickHair);
            } else {
                tl = imgTile(it.img, num, active, pickHair);
            }
            function pickHair() {
                hair.style = it.d;
                hair.texture = 0;
                S.hairTextures = it.t || 1;
                sendHair().then(function () { if (S && S.section === 'hair') keepScroll(function () { renderPanel(false); }); });
                keepScroll(function () { renderPanel(false); });
                renderFooter();
                renderSections();
            }
            g.appendChild(tl);
        });
        if (!list.length) g.appendChild(el('div', 'empty', esc(t('common.nothing'))));
        b.appendChild(g);
        c.appendChild(b);

        if (S.hairTextures > 1) {
            var v = block(null);
            v.appendChild(stepper(esc(t('common.variant')) + ' ' + (hair.texture + 1) + ' <em>/ ' + S.hairTextures + '</em>',
                function () { hair.texture = (hair.texture - 1 + S.hairTextures) % S.hairTextures; sendHair(); keepScroll(function () { renderPanel(false); }); renderFooter(); },
                function () { hair.texture = (hair.texture + 1) % S.hairTextures; sendHair(); keepScroll(function () { renderPanel(false); }); renderFooter(); }));
            $('controls').appendChild(v);
        }
        var colors = S.p.colors.hair;
        var bc = block(t('common.color'), t('common.colors', { n: colors.length }));
        bc.appendChild(palette(colors, hair.color, function (i) { hair.color = i; sendHair(); keepScroll(function () { renderPanel(false); }); renderFooter(); renderSections(); }));
        c.appendChild(bc);
        var bh = block(t('common.highlight'));
        bh.appendChild(palette(colors, hair.highlight, function (i) { hair.highlight = i; sendHair(); keepScroll(function () { renderPanel(false); }); renderFooter(); renderSections(); }));
        c.appendChild(bh);
    }

    function pageOverlays(c, keys, colors) {
        $('tabs').innerHTML = '';
        var k = S.sub[S.section];
        var count = S.p.overlays[k] || 0;
        var o = overlay(k);
        $('panel-title').textContent = t('sections.' + S.section);
        $('panel-sub').textContent = t('common.gameList');

        var top = block(null);
        top.appendChild(chips(keys.map(function (x) { return [x, t('overlays.' + x)]; }), k, function (v) { S.sub[S.section] = v; renderPanel(true); }));
        $('controls').appendChild(top);
        var b = block(null);
        var g = el('div', 'grid');
        g.appendChild(tile('', '<span class="word">' + esc(t('common.none')) + '</span>', overlayOff(o), function () { setOverlay(k, -1); keepScroll(function () { renderPanel(false); }); }));
        for (var i = 0; i < count; i++) {
            (function (s) {
                g.appendChild(pictureTile(overlayPicture(k, s + 1), s + 1, !overlayOff(o) && o.style === s, function () {
                    setOverlay(k, s);
                    keepScroll(function () { renderPanel(false); });
                }));
            })(i);
        }
        b.appendChild(g);
        c.appendChild(b);

        if (!overlayOff(o)) {
            var bo = block(t('common.opacity'));
            bo.appendChild(slider(t('common.opacity'), o.opacity, 0, 1, 0.05, function (v) { return Math.round(v * 100) + ' %'; },
                function (v) { o.opacity = v; if (v > 0) o.lastOpacity = v; sendOverlays(); renderFooter(); }));
            c.appendChild(bo);
            var bc = block(t('common.color'), t('common.colors', { n: colors.length }));
            bc.appendChild(palette(colors, o.color, function (i) {
                o.color = i; o.secondColor = i;
                sendOverlays();
                keepScroll(function () { renderPanel(false); });
                renderFooter();
                renderSections();
            }));
            c.appendChild(bc);
        }
    }

    function isWorn(tt) {
        return (S.data.tattoos[tt.zone] || []).some(function (w) { return w.name === tt.name; });
    }

    function tattooRow(tt, removable) {
        var worn = isWorn(tt);
        var inCart = !!S.cart[tt.name];
        var removed = !!S.removals[tt.name];
        var pr = S.p.prices || {};
        var price, state;
        if (worn) {
            price = removed ? (pr.tattooRemove ? money(pr.tattooRemove) : t('tattoo.free')) : t('tattoo.worn');
            state = removed ? t('tattoo.toRemove') : t('tattoo.remove');
        } else {
            price = S.p.mode === 'creation' ? t('tattoo.free') : money(tt.price || 0);
            state = inCart ? t('tattoo.inCart') : t('tattoo.try');
        }
        var r = el('button', 'row' + (inCart || removed ? ' active' : '') + (removed ? ' removed' : ''),
            '<span class="pic">' + icon('needle') + '</span>' +
            '<span><b>' + esc(tt.label || tt.name) + '</b><small>' + esc(removable ? t('sections.' + tt.zone) + ' · ' + collectionName(tt.collection) : collectionName(tt.collection)) + '</small></span>' +
            '<span class="price">' + esc(price) + '<small>' + esc(state) + '</small></span>');
        var pic = r.querySelector('.pic');
        withPicture(tattooPicture(tt), function (img) {
            pic.innerHTML = '';
            pic.classList.add('photo');
            pic.appendChild(img);
        });
        return on(r, function () {
            if (worn) { S.removals[tt.name] = !removed; }
            else if (inCart) { delete S.cart[tt.name]; }
            else { S.cart[tt.name] = tt; }
            previewTattoos();
            keepScroll(function () { renderPanel(false); });
            renderFooter();
            renderSections();
        });
    }

    function pageZone(c, only) {
        var zone = only || S.section;
        var all = (S.p.tattoos && S.p.tattoos[zone]) || [];
        var base = all.filter(function (x) { return !x.addon; });
        var added = all.filter(function (x) { return x.addon; });
        var tab = tabs(base.length, added.length);
        var list = tab === 'new' ? added : base;
        $('panel-title').textContent = t('sections.' + zone);
        $('panel-sub').textContent = tab === 'new' ? t('tattoo.newTattoos') : t('tattoo.gameTattoos');

        var s = el('label', 'search', icon('search'));
        var input = el('input');
        input.placeholder = t('common.search');
        input.value = S.search;
        input.addEventListener('input', function () {
            S.search = input.value;
            fillList();
        });
        s.appendChild(input);
        $('controls').appendChild(s);

        var l = el('div', 'list');
        c.appendChild(l);
        function fillList() {
            l.innerHTML = '';
            var q = S.search.trim().toLowerCase();
            var shown = list.filter(function (x) {
                return !q || String(x.label || x.name).toLowerCase().indexOf(q) >= 0 || collectionName(x.collection).toLowerCase().indexOf(q) >= 0;
            });
            shown.forEach(function (x) { l.appendChild(tattooRow(x, false)); });
            if (!shown.length) l.appendChild(el('div', 'empty', esc(q ? t('common.noResult') : t('common.nothing'))));
        }
        fillList();
    }

    function pageTattoos(c) {
        var zone = S.sub.tattoos || 'ZONE_TORSO';
        var b = block(null);
        b.appendChild(chips(ZONES.map(function (z) { return [z, t('sections.' + z)]; }), zone, function (z) {
            S.sub.tattoos = z;
            S.search = '';
            camera(CAMERA[z] || 'chest');
            renderPanel(true);
        }));
        $('controls').appendChild(b);
        pageZone(c, zone);
        $('panel-title').textContent = t('sections.tattoos');
    }

    function component(id) {
        S.data.components = S.data.components || [];
        for (var i = 0; i < S.data.components.length; i++) {
            if (S.data.components[i].component_id === id) return S.data.components[i];
        }
        var c = { component_id: id, drawable: 0, texture: 0 };
        S.data.components.push(c);
        return c;
    }

    function pageClothes(c) {
        $('tabs').innerHTML = '';
        var cats = (S.p.clothes && S.p.clothes.categories) || [];
        $('panel-title').textContent = t('sections.clothes');
        $('panel-sub').textContent = t('clothes.starter');
        if (!cats.length) { c.appendChild(el('div', 'empty', esc(t('common.nothing')))); return; }
        var cat = cats.filter(function (x) { return x.id === S.sub.clothes; })[0] || cats[0];
        S.sub.clothes = cat.id;
        var comp = component(cat.id);
        function send() { post('pa_component', { component_id: cat.id, drawable: comp.drawable, texture: comp.texture }); }

        var top = block(null);
        top.appendChild(chips(cats.map(function (x) { return [x.id, t('clothes.' + x.key)]; }), cat.id, function (v) {
            S.sub.clothes = v;
            renderPanel(true);
        }));
        $('controls').appendChild(top);
        var b = block(null);
        var g = el('div', 'grid');
        cat.items.forEach(function (it) {
            g.appendChild(imgTile(it.img, it.d, comp.drawable === it.d, function () {
                comp.drawable = it.d;
                comp.texture = 0;
                send();
                keepScroll(function () { renderPanel(false); });
            }));
        });
        if (!cat.items.length) g.appendChild(el('div', 'empty', esc(t('common.nothing'))));
        var cur = cat.items.filter(function (x) { return x.d === comp.drawable; })[0];
        var n = cur ? cur.t : 1;
        if (n > 1) {
            top.appendChild(stepper(esc(t('common.variant')) + ' ' + (comp.texture + 1) + ' <em>/ ' + n + '</em>',
                function () { comp.texture = (comp.texture - 1 + n) % n; send(); keepScroll(function () { renderPanel(false); }); },
                function () { comp.texture = (comp.texture + 1) % n; send(); keepScroll(function () { renderPanel(false); }); }));
        }
        b.appendChild(g);
        c.appendChild(b);
    }

    function pageWorn(c) {
        $('tabs').innerHTML = '';
        var worn = [];
        ZONES.forEach(function (z) { (S.data.tattoos[z] || []).forEach(function (tt) { worn.push(tt); }); });
        $('panel-title').textContent = t('sections.worn');
        $('panel-sub').textContent = t('tattoo.wornCount', { n: worn.length });
        var l = el('div', 'list');
        worn.forEach(function (tt) { l.appendChild(tattooRow(tt, true)); });
        cartList().forEach(function (tt) { l.appendChild(tattooRow(tt, true)); });
        if (!worn.length && !cartList().length) l.appendChild(el('div', 'empty', esc(t('tattoo.nothingWorn'))));
        c.appendChild(l);
    }

    function render() {
        renderTitle();
        renderSections();
        renderPanel(true);
        renderKeys();
    }

    function renderTitle() {
        var pr = S.p.prices || {};
        var price = S.p.mode === 'surgeon' ? money(pr.surgeon || 0) : money(pr.category || 0);
        var hint = S.p.mode === 'creation' ? '' : t('modeHints.' + S.p.mode, { price: price });
        $('title-text').innerHTML = '<b>' + esc(t('modes.' + S.p.mode)) + '</b>' + (hint ? '<small>' + esc(hint) + '</small>' : '');
    }

    function sectionBadge(k) {
        if (S.p.mode === 'barber') {
            var keys = k === 'hair' ? ['hair'] : k === 'facialhair' ? FACIAL : k === 'makeup' ? MAKEUP : [];
            var changed = keys.some(function (x) { return x === 'hair' ? !same(S.data.hair, S.origin.hair) : overlayChanged(x); });
            return changed ? '✓' : null;
        }
        if (S.p.mode === 'tattoo') {
            var n = cartList().filter(function (tt) { return tt.zone === k; }).length;
            if (k === 'worn') n = removalCount();
            return n ? String(n) : null;
        }
        return null;
    }

    function renderSections() {
        var box = $('sections');
        box.innerHTML = '';
        (S.p.sections || []).forEach(function (k) {
            var b = el('button', 'section' + (k === S.section ? ' active' : ''), icon(k) + '<span>' + esc(t('sections.' + k)) + '</span>');
            var badge = sectionBadge(k);
            if (badge) b.appendChild(el('i', 'badge', esc(badge)));
            box.appendChild(on(b, function () { go(k); }));
        });
    }

    function go(k) {
        if (!S || S.section === k) return;
        S.section = k;
        S.search = '';
        renderSections();
        renderPanel(true);
        camera(CAMERA[k] || 'face');
    }

    function renderPanel(top) {
        var c = $('content');
        c.innerHTML = '';
        $('controls').innerHTML = '';
        var k = S.section;
        if (k === 'heritage') pageHeritage(c);
        else if (k === 'face') pageFace(c);
        else if (k === 'skin') pageSkin(c);
        else if (k === 'eyes') pageEyes(c);
        else if (k === 'hair') pageHair(c);
        else if (k === 'facialhair') pageOverlays(c, FACIAL, S.p.colors.hair);
        else if (k === 'makeup') pageOverlays(c, MAKEUP, S.p.colors.makeup);
        else if (k === 'worn') pageWorn(c);
        else if (ZONES.indexOf(k) >= 0) pageZone(c);
        else if (k === 'clothes') pageClothes(c);
        else if (k === 'tattoos') pageTattoos(c);
        if (top) c.scrollTop = 0;
        renderFooter();
    }

    function renderFooter() {
        var f = $('footer');
        f.innerHTML = '';
        var b = bill();
        var creation = S.p.mode === 'creation';
        f.appendChild(el('div', 'total', '<small>' + esc(b.label) + '</small><b>' + esc(creation ? t('footer.free') : money(b.total)) + '</b>'));
        if (!creation) f.appendChild(on(el('button', 'button', esc(t('footer.cancel'))), cancel));
        var main = on(el('button', 'button solid', esc(creation ? t('footer.finish') : t('footer.pay'))), function () {
            if (creation) askModal('finish', save); else save();
        });
        main.disabled = S.busy || !b.changed;
        f.appendChild(main);
    }

    function renderKeys() {
        var k = $('keys');
        k.innerHTML = '';
        if (!S) return;
        function key(kbd, label, cam) {
            var e = el(cam ? 'button' : 'div', 'key' + (cam && cam === S.camera ? ' active' : ''), '<kbd>' + esc(kbd) + '</kbd>' + esc(label));
            if (cam) on(e, function () { camera(cam); });
            k.appendChild(e);
        }
        if (S.hidden) { key(keyOf('hide', 'H'), t('keys.show')); return; }
        key(t('keys.click'), t('keys.rotate'));
        key(t('keys.wheel'), t('keys.zoom'));
        key(keyOf('face', '1'), t('keys.face'), 'face');
        key(keyOf('chest', '2'), t('keys.chest'), 'chest');
        key(keyOf('body', '3'), t('keys.body'), 'body');
        key(keyOf('hide', 'H'), t('keys.hide'));
    }

    function notice(text) {
        var n = $('notice');
        if (!text) { n.classList.add('hidden'); return; }
        n.textContent = text;
        n.classList.remove('hidden');
    }

    function save() {
        if (!S || S.busy) return;
        S.busy = true;
        notice(null);
        renderFooter();
        post('pa_save', { appearance: finalAppearance(), total: bill().total }).then(function (r) {
            if (!S) return;
            S.busy = false;
            if (!r || r.ok !== true) {
                notice((r && r.error) || '...');
                renderFooter();
            }
        });
    }

    function cancel() { if (S && !S.busy) post('pa_cancel'); }

    var modalYes = null;
    function askModal(kind, yes) {
        $('modal-title').textContent = t('modal.' + kind + 'Title');
        $('modal-text').textContent = t('modal.' + kind + 'Text');
        $('modal-yes').textContent = t('modal.' + kind + 'Yes');
        $('modal-no').textContent = t('modal.' + kind + 'No');
        modalYes = yes;
        $('modal').classList.remove('hidden');
    }
    function closeModal() { $('modal').classList.add('hidden'); modalYes = null; }
    function modalOpen() { return !$('modal').classList.contains('hidden'); }
    $('modal-no').addEventListener('click', closeModal);
    $('modal-yes').addEventListener('click', function () { var fn = modalYes; closeModal(); if (fn) fn(); });

    function toggleHidden() {
        S.hidden = !S.hidden;
        $('app').classList.toggle('hidden', S.hidden);
        renderKeys();
    }

    document.addEventListener('keydown', function (e) {
        if (!S) return;
        var typing = e.target && e.target.tagName === 'INPUT' && e.target.type !== 'range';
        if (e.key === 'Escape') {
            if (typing) { e.target.blur(); return; }
            if (modalOpen()) { closeModal(); return; }
            if (S.p.mode !== 'creation') askModal('quit', cancel);
            return;
        }
        if (typing || modalOpen()) return;
        var k = e.key.toUpperCase();
        if (k === keyOf('hide', 'H')) toggleHidden();
        else if (!S.hidden && k === keyOf('face', '1')) camera('face');
        else if (!S.hidden && k === keyOf('chest', '2')) camera('chest');
        else if (!S.hidden && k === keyOf('body', '3')) camera('body');
    });

    var dragging = false, lastX = 0, sumX = 0, queued = false;
    function freeArea(target) {
        if (!S || modalOpen()) return false;
        return !(target && target.closest && target.closest('.ui'));
    }
    function flushDrag() {
        queued = false;
        if (!sumX) return;
        var dx = sumX;
        sumX = 0;
        post('pa_cam_rotate', { dx: dx });
    }
    document.addEventListener('mousedown', function (e) {
        if (e.button !== 0 || !freeArea(e.target)) return;
        dragging = true;
        lastX = e.clientX;
        sumX = 0;
        document.body.style.cursor = 'grabbing';
        e.preventDefault();
    }, true);
    document.addEventListener('mousemove', function (e) {
        if (!dragging) return;
        sumX += (e.clientX - lastX) / window.innerWidth;
        lastX = e.clientX;
        if (!queued) { queued = true; setTimeout(flushDrag, 30); }
    }, true);
    document.addEventListener('mouseup', function () {
        if (!dragging) return;
        flushDrag();
        dragging = false;
        document.body.style.cursor = '';
    }, true);
    document.addEventListener('wheel', function (e) {
        if (!freeArea(e.target) || e.deltaY === 0) return;
        post('pa_cam_zoom', { dir: e.deltaY < 0 ? 1 : -1 });
    }, { passive: true });
    document.addEventListener('contextmenu', function (e) { if (S) e.preventDefault(); }, true);
})();
