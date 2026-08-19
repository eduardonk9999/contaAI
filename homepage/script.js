/* ============================================================
   ContAI — landing page
   JavaScript puro. A página deve continuar legível sem ele.
   ============================================================ */

/**
 * Destino do botão "Começar agora" e dos CTAs dos planos.
 * Vazio → a página apenas rola até a demonstração.
 * Preenchido → navega para o endereço informado.
 * Exemplo: const APP_URL = "https://app.contai.com.br";
 */
const APP_URL = "";

(function () {
  "use strict";

  // Marca que o JS está ativo — só então as animações de entrada são aplicadas.
  document.documentElement.classList.add("js");

  document.addEventListener("DOMContentLoaded", function () {

    /* ---------- Menu mobile ---------- */
    const toggle = document.getElementById("navToggle");
    const menu = document.getElementById("navMenu");

    function closeMenu() {
      if (!toggle || !menu) return;
      menu.classList.remove("is-open");
      toggle.setAttribute("aria-expanded", "false");
      toggle.setAttribute("aria-label", "Abrir menu de navegação");
    }

    if (toggle && menu) {
      toggle.addEventListener("click", function () {
        const isOpen = menu.classList.toggle("is-open");
        toggle.setAttribute("aria-expanded", String(isOpen));
        toggle.setAttribute("aria-label", isOpen ? "Fechar menu de navegação" : "Abrir menu de navegação");
      });

      // Fecha ao escolher um destino.
      menu.addEventListener("click", function (event) {
        if (event.target.closest("a")) closeMenu();
      });

      // Fecha com Esc e devolve o foco ao botão.
      document.addEventListener("keydown", function (event) {
        if (event.key === "Escape" && menu.classList.contains("is-open")) {
          closeMenu();
          toggle.focus();
        }
      });

      // Fecha ao clicar fora.
      document.addEventListener("click", function (event) {
        if (!menu.classList.contains("is-open")) return;
        if (menu.contains(event.target) || toggle.contains(event.target)) return;
        closeMenu();
      });

      // Ao passar para o layout de desktop, o menu volta ao estado neutro.
      window.addEventListener("resize", function () {
        if (window.innerWidth >= 768) closeMenu();
      });
    }

    /* ---------- Rolagem suave com compensação do header fixo ---------- */
    const header = document.querySelector(".site-header");

    document.querySelectorAll('a[href^="#"]').forEach(function (link) {
      link.addEventListener("click", function (event) {
        const id = link.getAttribute("href");
        if (!id || id === "#") return;

        const target = document.querySelector(id);
        if (!target) return;

        event.preventDefault();

        const offset = header ? header.offsetHeight + 12 : 0;
        const top = target.getBoundingClientRect().top + window.pageYOffset - offset;
        const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

        window.scrollTo({ top: top, behavior: reduced ? "auto" : "smooth" });
        history.replaceState(null, "", id);
      });
    });

    /* ---------- Animação de entrada ---------- */
    const revealables = document.querySelectorAll(".reveal");

    if (!("IntersectionObserver" in window)) {
      revealables.forEach(function (el) { el.classList.add("is-visible"); });
    } else {
      const observer = new IntersectionObserver(function (entries) {
        entries.forEach(function (entry) {
          if (!entry.isIntersecting) return;
          entry.target.classList.add("is-visible");
          observer.unobserve(entry.target);
        });
      }, { threshold: 0.12, rootMargin: "0px 0px -40px 0px" });

      revealables.forEach(function (el) { observer.observe(el); });
    }

    /* ---------- Destino dos CTAs ---------- */
    if (APP_URL) {
      document.querySelectorAll("#ctaButton, [data-app-link]").forEach(function (el) {
        el.setAttribute("href", APP_URL);
      });
    }

    /* ---------- Ano corrente no rodapé ---------- */
    const year = document.getElementById("year");
    if (year) year.textContent = String(new Date().getFullYear());
  });
})();
