# Ansible

I like to use ansible for different reasons:
- easy
- very flexible
- idempotent (mostly)
- declarative
- good to know also for other things

## General

I dont want to dig into Ansible itself, for that there are [docs](https://docs.ansible.com/).

I do have a few [roles](../ansible/roles) and [group_vars](../ansible/group_vars) that I set up for my system.
The orchestration is done in [site.yml](../ansible/site.yml), so this is the `playbook` to run.

## Roles



## Alternatives

Some people like [chezmoi](https://www.chezmoi.io/) which is supposed to handle some things I do with ansible, by being simpler and with smaller footprint.
There are other nice dotfile management tools like [dotbot](https://github.com/anishathalye/dotbot).
