# -*- coding: utf-8 -*-
# vim: set syntax=yaml ts=2 sw=2 sts=2 et :

##
# qvm.sys-gui
# ===========
##

qubes-template-{{ salt['pillar.get']('qvm:sys-gui:template', 'fedora-30-xfce') }}:
  pkg.installed: []

{% from "qvm/template.jinja" import load -%}

{% load_yaml as defaults -%}
name:          sys-gui
present:
  - label:     black
  - maxmem:    4000
  - template:  {{ salt['pillar.get']('qvm:sys-gui:template', 'fedora-30-xfce') }}
prefs:
  - netvm:     ""
  - guivm:     dom0
  - audiovm:   ""
  - autostart: true
service:
  - enable:
    - guivm-gui-agent
{%- endload %}

{{ load(defaults) }}

# dom0 is GuiVM for sys-gui
dom0-guivm-gui-agent:
  qvm.vm:
    - name: dom0
    - service:
      - enable:
        - guivm-gui-agent

# Set 'dom0' keyboard-layout feature
dom0-keyboard-layout:
  cmd.run:
    - name: qvm-features dom0 keyboard-layout {{ salt['keyboard.get_x']() }}

# Set 'sys-gui' keyboard-layout feature
sys-gui-keyboard-layout:
  cmd.run:
    - name: qvm-features sys-gui keyboard-layout {{ salt['keyboard.get_x']() }}
    - require:
      - qvm: sys-gui

# Setup Qubes RPC policy
sys-gui-rpc:
  file.managed:
    - name: /etc/qubes/policy.d/30-sys-gui.policy
    - contents: |
        qubes.GetImageRGBA                  *   sys-gui             @tag:guivm-sys-gui          allow
        qubes.GetAppmenus                   *   sys-gui             @tag:guivm-sys-gui          allow
        qubes.SetMonitorLayout              *   sys-gui             @tag:guivm-sys-gui          allow
        qubes.StartApp                      *   sys-gui             @tag:guivm-sys-gui          allow
        qubes.StartApp                      *   sys-gui             @dispvm:@tag:guivm-sys-gui  allow
        qubes.SyncAppMenus                  *   @tag:guivm-sys-gui  dom0                        allow   target=sys-gui
        qubes.WaitForSession                *   sys-gui             @tag:guivm-sys-gui          allow


# GuiVM (AdminVM) with local 'rwx' permissions
/etc/qubes-rpc/policy/include/admin-local-rwx:
  file.append:
    - text: |
        sys-gui @tag:guivm-sys-gui allow,target=dom0

# GuiVM (AdminVM) with global 'ro' permissions
{% if salt['pillar.get']('qvm:sys-gui:admin-global-permissions') == 'ro' %}
/etc/qubes-rpc/policy/include/admin-global-ro:
  file.append:
    - text: |
        sys-gui @adminvm allow,target=dom0
        sys-gui @tag:guivm-sys-gui allow,target=dom0
{% endif %}

{% if salt['pillar.get']('qvm:sys-gui:admin-global-permissions') == 'rwx' %}
# GuiVM (AdminVM) with global 'rwx' permissions
/etc/qubes-rpc/policy/include/admin-global-rwx:
  file.append:
    - text: |
        sys-gui @adminvm allow,target=dom0
        sys-gui @tag:guivm-sys-gui allow,target=dom0
{% endif %}