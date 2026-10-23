/**
 * Chelan County CMSAdmin 2.0 - One Page Studio Runtime
 * Smooth Anchor Scrolling, Section Spy, and Accessible Mobile Navigation
 */
(function () {
  'use strict';
  document.addEventListener('DOMContentLoaded', function () {
    // 1. Smooth Scrolling for Internal Hash Anchors
    var anchorLinks = document.querySelectorAll('a[href^="#"]');
    anchorLinks.forEach(function (anchor) {
      anchor.addEventListener('click', function (e) {
        var href = this.getAttribute('href');
        if (!href || href === '#') return;
        if (href === '#top') {
          e.preventDefault();
          window.scrollTo({ top: 0, behavior: 'smooth' });
          return;
        }
        var target = document.querySelector(href);
        if (target) {
          e.preventDefault();
          target.scrollIntoView({ behavior: 'smooth' });
          if (history.pushState) {
            history.pushState(null, '', href);
          }
        }
      });
    });
    // 2. Scrollspy Active Link Highlighting
    var navLinks = document.querySelectorAll('.ops-nav a[href^="#"]');
    var sections = document.querySelectorAll('.ops-section[id]');
    if (navLinks.length && sections.length && 'IntersectionObserver' in window) {
      var spyObserver = new IntersectionObserver(function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            var id = entry.target.getAttribute('id');
            navLinks.forEach(function (link) {
              var href = link.getAttribute('href');
              if (href === '#' + id) {
                link.classList.add('active');
              } else if (!link.classList.contains('ops-cta-btn')) {
                link.classList.remove('active');
              }
            });
          }
        });
      }, { rootMargin: '-20% 0px -60% 0px', threshold: 0 });
      sections.forEach(function (sec) { spyObserver.observe(sec); });
    }
    // 3. Mobile Navigation Drawer Toggle
    var navToggle = document.getElementById('opsNavToggle');
    var navMenu = document.getElementById('opsNavMenu');
    if (navToggle && navMenu) {
      navToggle.addEventListener('click', function () {
        var isOpen = navMenu.classList.toggle('ops-nav-open');
        navToggle.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
      });
      navMenu.querySelectorAll('a').forEach(function (link) {
        link.addEventListener('click', function () {
          navMenu.classList.remove('ops-nav-open');
          navToggle.setAttribute('aria-expanded', 'false');
        });
      });
    }
  });
})();

