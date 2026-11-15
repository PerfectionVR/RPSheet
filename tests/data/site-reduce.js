// Makes the three site-*.txt files of this folder. Run it in the browser console on
// the rules site's classes page (it uses the site's own loader, which resolves the
// setting's classes that are copies of core ones); it returns { classes, subclasses,
// options }, each the text of one file. Names and numbers only: no feature text.
// Line forms (read by tests/t-conform-site-lib.lua):
//   CLASS|name|source|core class it reskins|its source|hero     SUB|class|class source|short name|name|source||
//   hd, primary, saves, armor, weapons, tools, skills|count|list, caster|progression|ability|change=
//   cantrips, prepared, spellbook, arcanum, mastery, featprog, optprog: progressions by level
//   col|label|twenty values     slots|slots per spell level as digits, by level
//   mc|what a class taken later gives     SP|block|kind|level|spells always prepared or known
//   L<level>|feature;feature     name@WoW = from the setting's book, * = a subclass feature level,
//                                [a/b(c)] = the named parts of the feature
//   OPT|type|name|source|level it asks|option it builds on|cost|what it costs
(async () => {
    const all = await DataUtil.class.loadJSON();
    const tag = s => String(s).replace(/\{@\w+ ([^|}]*)[^}]*\}/g, '$1');
    const plain = o => JSON.stringify(o).replace(/"/g, '');
    const cell = v => {
        if (v == null) return '-';
        if (typeof v === 'object') {
            if (v.type === 'dice') return v.toRoll.map(r => r.number + 'd' + r.faces).join('+');
            if (v.type === 'bonus' || v.type === 'bonusSpeed') return '+' + v.value;
            return JSON.stringify(v);
        }
        return tag(v).replace(/,/g, ' ').replace(/—|–/g, '-');
    };
    const steps = p => Array.isArray(p) ? p.join(',') : plain(p);
    const kids = f => {
        const out = [];
        const walk = es => {
            for (const e of (Array.isArray(es) ? es : [])) {
                if (!e || typeof e !== 'object' || e.subclassShortName || e.className) continue;
                if (e.type === 'refOptionalfeature') out.push(e.optionalfeature.split('|')[0]);
                else if (e.type === 'refClassFeature') out.push('>' + e.classFeature.split('|')[0]);
                else if (e.type === 'table') { if (e.caption) out.push('T:' + tag(e.caption)); }
                else if (e.name && (e.type === 'entries' || e.type === 'item' || e.type === 'itemSub')) {
                    const inner = kids(e);
                    out.push(tag(e.name).replace(/[.:]$/, '') + (inner.length ? '(' + inner.join('/') + ')' : ''));
                } else walk(e.entries || e.items);
            }
        };
        walk(f.entries);
        return out;
    };
    const fname = f => f.name + (f.source && f.source !== 'XPHB' ? '@' + f.source : '') + (f.gainSubclassFeature ? '*' : '')
        + (kids(f).length ? '[' + kids(f).join('/') + ']' : '');
    const spells = as => {
        const lines = [];
        (as || []).forEach((b, i) => {
            for (const kind of ['prepared', 'known', 'innate', 'expanded']) {
                for (const [lv, v] of Object.entries(b[kind] || {})) {
                    const names = [];
                    const walk = x => {
                        if (typeof x === 'string') names.push(x.split('|')[0].split('#')[0]);
                        else if (Array.isArray(x)) x.forEach(walk);
                        else if (x && typeof x === 'object') {
                            if (x.choose !== undefined) names.push('choose:' + (typeof x.choose === 'string' ? x.choose : JSON.stringify(x.choose)) + (x.count ? 'x' + x.count : ''));
                            else if (x.all !== undefined) names.push('all:' + x.all);
                            else Object.entries(x).forEach(([k, y]) => { const before = names.length; walk(y); for (let j = before; j < names.length; j++) names[j] += '@' + k; });
                        }
                    };
                    walk(v);
                    lines.push('SP|' + (b.name || i) + '|' + kind + '|' + lv + '|' + names.join(';'));
                }
            }
        });
        return lines;
    };
    const table = (groups, L) => {
        for (const g of groups || []) {
            if (g.rowsSpellProgression) L.push('slots|' + g.rowsSpellProgression.map(r => r.join('').replace(/0+$/, '') || '0').join(','));
            else g.colLabels.forEach((lab, i) => L.push('col|' + tag(lab) + '|' + g.rows.map(r => cell(r[i])).join(',')));
        }
    };
    const levels = (by, L, upTo) => {
        if (upTo) for (let lv = 1; lv <= upTo; lv++) L.push('L' + lv + '|' + (by[lv] || []).join(';'));
        else for (const lv of Object.keys(by).sort((a, b) => a - b)) L.push('L' + lv + '|' + by[lv].join(';'));
    };
    const cls = c => {
        const L = ['CLASS|' + c.name + '|' + c.source + '|' + (c.reskinOf || []).join(',') + '|' + (c.isHero ? 'hero' : '')];
        const sp = c.startingProficiencies || {};
        L.push('hd|' + c.hd.faces, 'primary|' + c.primaryAbility.map(o => Object.keys(o).join('+')).join(' or '), 'saves|' + c.proficiency.join(','));
        L.push('armor|' + (sp.armor || []).map(a => typeof a === 'string' ? tag(a) : tag(a.full || a.proficiency)).join(','));
        L.push('weapons|' + (sp.weapons || []).map(a => typeof a === 'string' ? tag(a) : tag(a.proficiency) + (a.optional ? '?' : '')).join(','));
        L.push('tools|' + (sp.tools || []).map(tag).join(','));
        L.push('skills|' + (sp.skills || []).map(s => s.choose ? s.choose.count + '|' + s.choose.from.join(',') : (s.any ? s.any + '|any' : JSON.stringify(s))).join(' & '));
        L.push('caster|' + (c.casterProgression || '') + '|' + (c.spellcastingAbility || '') + '|change=' + (c.preparedSpellsChange || ''));
        if (c.cantripProgression) L.push('cantrips|' + c.cantripProgression.join(','));
        if (c.preparedSpellsProgression) L.push('prepared|' + c.preparedSpellsProgression.join(','));
        if (c.spellsKnownProgressionFixed) L.push('spellbook|' + c.spellsKnownProgressionFixed.join(','));
        if (c.spellsKnownProgressionFixedByLevel) L.push('arcanum|' + plain(c.spellsKnownProgressionFixedByLevel));
        if (c.itemMasteriesProgression) L.push('mastery|' + steps(c.itemMasteriesProgression));
        for (const fp of c.featProgression || []) L.push('featprog|' + fp.name + '|' + (fp.category || []).join(',') + '|' + plain(fp.progression));
        for (const op of c.optionalfeatureProgression || []) L.push('optprog|' + op.name + '|' + (op.featureType || []).join(',') + '|' + steps(op.progression));
        table(c.classTableGroups, L);
        const mc = c.multiclassing || {}, pg = mc.proficienciesGained || {};
        L.push('mc|req=' + plain(mc.requirements || null) + '|armor=' + (pg.armor || []).map(a => typeof a === 'string' ? a : tag(a.full || a.proficiency)).join(',')
            + '|weapons=' + (pg.weapons || []).map(a => typeof a === 'string' ? tag(a) : tag(a.proficiency)).join(',') + '|tools=' + (pg.tools || []).map(tag).join(',')
            + '|skills=' + (pg.skills || []).map(s => s.choose ? s.choose.count + ':' + s.choose.from.join(',') : JSON.stringify(s)).join('&'));
        L.push('subclassTitle|' + (c.subclassTitle || ''));
        spells(c.additionalSpells).forEach(x => L.push(x));
        const by = {};
        for (const f of (c.classFeatures || []).flat()) (by[f.level] = by[f.level] || []).push(fname(f));
        levels(by, L, 20);
        return L.join('\n');
    };
    const sub = s => {
        const L = ['SUB|' + s.className + '|' + s.classSource + '|' + s.shortName + '|' + s.name + '|' + s.source + '|' + (s.casterProgression || '') + '|' + (s.spellcastingAbility || '')];
        spells(s.additionalSpells).forEach(x => L.push(x));
        if (s.cantripProgression) L.push('cantrips|' + s.cantripProgression.join(','));
        table(s.subclassTableGroups, L);
        for (const op of s.optionalfeatureProgression || []) L.push('optprog|' + op.name + '|' + (op.featureType || []).join(',') + '|' + steps(op.progression));
        const by = {};
        const add = f => (by[f.level] = by[f.level] || []).push(fname(f));
        // a level's heading holds the features of that level
        for (const h of (s.subclassFeatures || []).flat()) {
            const inner = (h.entries || []).filter(e => e && typeof e === 'object' && e.subclassShortName);
            if (!inner.length) { if (h.name) add(h); continue; }
            if (h.name && h.name !== s.name && !/^Subclass Feature/.test(h.name)) add({ ...h, entries: (h.entries || []).filter(e => !(e && e.subclassShortName)) });
            inner.forEach(add);
        }
        levels(by, L);
        return L.join('\n');
    };
    // the feature lists are long: the parts of Spellcasting and Pact Magic are left out
    const trim = t => t.replace(/(Spellcasting(@WoW)?|Pact Magic)\[[^;\n]*?\](?=;|\n|$)/g, '$1');
    const wow = all.class.filter(c => c.source === 'WoW'), core = all.class.filter(c => c.source === 'XPHB');
    const classes = trim([...wow, ...core].map(cls).join('\n\n') + '\n');
    const subclasses = trim(all.subclass.filter(s => s.source === 'WoW' && s.classSource === 'WoW').map(sub).join('\n\n') + '\n');
    const o = await fetch('data/optionalfeatures.json').then(r => r.json());
    const options = o.optionalfeature.filter(x => (x.source === 'XPHB' || x.source === 'WoW') && x.featureType.some(t => ['EI', 'MM', 'MV:B'].includes(t))).map(x => {
        let level = '', needs = '';
        for (const p of x.prerequisite || []) {
            if (p.level) level = p.level.level;
            if (p.optionalfeature) needs = p.optionalfeature.map(s => s.split('|')[0]).join(',');
        }
        return ['OPT', x.featureType.join(','), x.name, x.source, level, needs, x.consumes ? (x.consumes.amount || 1) : '', (x.consumes || {}).name || ''].join('|');
    }).join('\n') + '\n';
    return { classes, subclasses, options };
})()
