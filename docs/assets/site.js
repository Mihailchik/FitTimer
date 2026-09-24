(function () {
  function stored() {
    try { return localStorage.getItem('ft_lang'); } catch (e) { return null; }
  }
  function save(lang) {
    try { localStorage.setItem('ft_lang', lang); } catch (e) {}
  }
  function detect() {
    var hash = (location.hash || '').replace('#', '').toLowerCase();
    if (hash === 'ru' || hash === 'en') return hash;
    var s = stored();
    if (s === 'ru' || s === 'en') return s;
    var nav = (navigator.language || 'ru').toLowerCase();
    return nav.indexOf('ru') === 0 ? 'ru' : 'en';
  }
  function apply(lang) {
    document.documentElement.lang = lang;
    document.querySelectorAll('[data-lang-ru]').forEach(function (el) {
      el.style.display = lang === 'ru' ? 'block' : 'none';
    });
    document.querySelectorAll('[data-lang-en]').forEach(function (el) {
      el.style.display = lang === 'en' ? 'block' : 'none';
    });
    document.querySelectorAll('[data-setlang]').forEach(function (btn) {
      btn.setAttribute('aria-pressed', btn.getAttribute('data-setlang') === lang ? 'true' : 'false');
    });
  }
  document.addEventListener('DOMContentLoaded', function () {
    apply(detect());
    document.querySelectorAll('[data-setlang]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var lang = btn.getAttribute('data-setlang');
        save(lang);
        apply(lang);
      });
    });
  });
})();
