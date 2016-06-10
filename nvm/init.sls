{% for name, config in pillar.get('nvm', {}).items() %}
{%- if config == None -%}
{%- set config = {} -%}
{%- endif -%}
{%- set user = salt['pillar.get']('users:' + name, {}) -%}
{%- set home = user.get('home', "/home/%s" % name) -%}

{%- if 'prime_group' in user and 'name' in user['prime_group'] %}
{%- set group = user.prime_group.name -%}
{%- else -%}
{%- set group = name -%}
{%- endif %}

{%- set installs = config.get('install', ['0.10']) %}
{%- set default = config.get('default', '0.10') %}

nvm_{{ name }}:
  git.latest:
    - name: git://github.com/creationix/nvm
    - target: {{ home }}/.nvm
  file.directory:
    - name: {{ home }}/.nvm
    - user: {{ name }}
    - group: {{ group }}
    - recurse:
      - user
      - group
    - require:
      - git: nvm_{{ name }}
      - cmd: nvm_{{ name }}
      - group: {{ group }}
      - user: {{ name }}
  cmd.run:
    - name: |
        source {{ home }}/.nvm/nvm.sh;
        {%- for version in installs %}
        nvm install {{ version }};
        {%- endfor %}
        nvm alias default {{ default }};
    - shell: "/bin/bash"
    - require:
      - pkg: nvm_deps

nvm_profile:
  file.blockreplace:
    - name: {{ home }}/.profile
    - marker_start: "#> Saltstack Managed Configuration START <#"
    - marker_end: "#> Saltstack Managed Configuration END <#"
    - append_if_not_found: true
    - content: |
        if [ -f "{{ home }}/.nvm/nvm.sh" ]; then
          source {{ home }}/.nvm/nvm.sh
        fi

nvm_deps:
  pkg.installed:
    - names:
      - build-essential
      - libssl-dev
      - curl

{% endfor %}
