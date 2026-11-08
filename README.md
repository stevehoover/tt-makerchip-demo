![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# Tiny Tapeout TL-Verilog (Makerchip) Project Template

- [Read the documentation for project](docs/info.md)

This is the [Tiny Tapeout Verilog template](https://github.com/TinyTapeout/ttsky-verilog-template)
adapted for [TL-Verilog](https://tl-x.org) and [Makerchip](https://makerchip.com). It is maintained
by its author, not by Tiny Tapeout.

## What is Tiny Tapeout?

Tiny Tapeout is an educational project that aims to make it easier and cheaper than ever to get your digital and analog designs manufactured on a real chip.

To learn more and get started, visit https://tinytapeout.com.

## Set up your TL-Verilog project

1. Design in [src/project.tlv](src/project.tlv) (TL-Verilog, Verilog, or both), in VS Code with the
   [Makerchip extension](https://marketplace.visualstudio.com/items?itemName=RedwoodEDA.makerchip)
   (recommended for this workspace). Compiling it in Makerchip simulates it with the Tiny Tapeout
   demo board in the VIZ view.
2. Edit the [info.yaml](info.yaml) and update information about your project, paying special attention to the `top_module` property. It must match `my_design` in `src/project.tlv` and the module instantiated in `test/tb.v`. If you are upgrading an existing Tiny Tapeout project, check out our [online info.yaml migration tool](https://tinytapeout.github.io/tt-yaml-upgrade-tool/).
3. Edit [docs/info.md](docs/info.md) and add a description of your project.
4. Adapt the testbench to your design. See [test/README.md](test/README.md) for more information.
5. Before each push, regenerate and commit `src/project.sv`, the Verilog that the Tiny Tapeout flow
   builds: `cd test && make verilog` (needs [SandPiper-SaaS](https://pypi.org/project/sandpiper-saas/):
   `pipx install sandpiper-saas`).

The GitHub action will automatically build the ASIC files using [LibreLane](https://www.zerotoasiccourse.com/terminology/librelane/).

## Enable GitHub actions to build the results page

- [Enabling GitHub Pages](https://tinytapeout.com/faq/#my-github-action-is-failing-on-the-pages-part)

## Resources

- [FAQ](https://tinytapeout.com/faq/)
- [Digital design lessons](https://tinytapeout.com/digital_design/)
- [Learn how semiconductors work](https://tinytapeout.com/siliwiz/)
- [Join the community](https://tinytapeout.com/discord)
- [Build your design locally](https://www.tinytapeout.com/guides/local-hardening/)

## What next?

- [Submit your design to the next shuttle](https://app.tinytapeout.com/).
- Edit [this README](README.md) and explain your design, how it works, and how to test it.
- Share your project on your social network of choice:
  - LinkedIn [#tinytapeout](https://www.linkedin.com/search/results/content/?keywords=%23tinytapeout) [@TinyTapeout](https://www.linkedin.com/company/100708654/)
  - Mastodon [#tinytapeout](https://chaos.social/tags/tinytapeout) [@matthewvenn](https://chaos.social/@matthewvenn)
  - X (formerly Twitter) [#tinytapeout](https://twitter.com/hashtag/tinytapeout) [@tinytapeout](https://twitter.com/tinytapeout)
  - Bluesky [@tinytapeout.com](https://bsky.app/profile/tinytapeout.com)
