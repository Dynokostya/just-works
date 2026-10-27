#!/usr/bin/env node

import { readFileSync, writeFileSync, existsSync, lstatSync, mkdirSync, cpSync, copyFileSync, rmSync, readdirSync, mkdtempSync, renameSync } from 'node:fs';
import { join, dirname, relative, resolve } from 'node:path';
import { homedir, tmpdir } from 'node:os';
import { createInterface } from 'node:readline';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const PACKAGE_ROOT = join(__dirname, '..');

// ---------------------------------------------------------------------------
// Colors
// ---------------------------------------------------------------------------
const isTTY = process.stdout.isTTY;
const GREEN  = isTTY ? '\x1b[0;32m' : '';
const YELLOW = isTTY ? '\x1b[0;33m' : '';
const RED    = isTTY ? '\x1b[0;31m' : '';
const BOLD   = isTTY ? '\x1b[1m'    : '';
const NC     = isTTY ? '\x1b[0m'    : '';

const info  = (msg) => console.log(`${GREEN}[+]${NC} ${msg}`);
const warn  = (msg) => console.log(`${YELLOW}[!]${NC} ${msg}`);
const error = (msg) => console.error(`${RED}[x]${NC} ${msg}`);

// ---------------------------------------------------------------------------
// Usage
// ---------------------------------------------------------------------------
function usage() {
  console.log(`Usage: just-works [OPTIONS]

Install just-works agents, skills, and settings globally.

Options:
  --personal         Use opinionated settings.json (permissions, hooks, sounds)
                     Default: minimal settings.json.default
  --azure            Use Azure OpenAI config instead of direct OpenAI API
  --skip-config         Skip installing settings/config files (still migrates a legacy rtk hook)
  --skip-statusline     Skip installing statusline-command.sh
  --skip-skills-claude  Skip installing Claude Code skills
  --skip-skills-codex   Skip installing Codex skills
  --claude-only      Install only Claude Code files (~/.claude/)
  --codex-only       Install only Codex files (~/.codex/, ~/.agents/)
  --dry-run          Show what would be installed without making changes
  --no-backup        Skip backup prompt, disable backups (for CI/non-interactive)
  -v, --version      Print version and exit
  -h, --help         Show this help message

Environment:
  CLAUDE_CONFIG_DIR  Claude Code config dir to install into (default ~/.claude)
  CODEX_HOME         Codex home to install into (default ~/.codex)

What gets installed:
  ~/.claude/
    agents/       Agent definitions (python-code-writer, prompt-writer, ...)
    skills/       Coding and prompting standards
    output-styles/  Selectable output styles (compressed, ...)
    settings.json             Permission and hook configuration
    CLAUDE.md                 Global behavioral instructions
    web-chat-prompt.md        Instructions for claude.ai chat
    statusline-command.sh     Status line script (needs jq)
    hooks/skill-guard.sh      Loads coding skills before the first code edit (needs jq)

  ~/.codex/
    agents/       Custom agent definitions (python-code-writer, prompt-writer, ...)
    config.toml   Codex CLI configuration (--azure for Azure OpenAI)
    hooks.json    Lifecycle hooks (notification)
    AGENTS.md     Global behavioral instructions

  ~/.agents/
    skills/       Coding and prompting standards (Codex discovery path)

Agents, skills and output styles are installed one entry at
a time. Other files in those directories are never touched. Each home keeps a
.just-works-manifest listing the entries it installed; entries that a later
version no longer ships are removed (after a backup, unless --no-backup).`);
}

// ---------------------------------------------------------------------------
// Parse arguments
// ---------------------------------------------------------------------------
const args = process.argv.slice(2);
const flags = {
  personal: false,
  azure: false,
  dryRun: false,
  claudeOnly: false,
  codexOnly: false,
  skipConfig: false,
  skipStatusline: false,
  skipSkillsClaude: false,
  skipSkillsCodex: false,
  noBackup: false,
};

for (const arg of args) {
  switch (arg) {
    case '--personal':          flags.personal = true; break;
    case '--azure':             flags.azure = true; break;
    case '--dry-run':           flags.dryRun = true; break;
    case '--claude-only':       flags.claudeOnly = true; break;
    case '--codex-only':        flags.codexOnly = true; break;
    case '--skip-config':       flags.skipConfig = true; break;
    case '--skip-statusline':   flags.skipStatusline = true; break;
    case '--skip-skills-claude': flags.skipSkillsClaude = true; break;
    case '--skip-skills-codex': flags.skipSkillsCodex = true; break;
    case '--no-backup':         flags.noBackup = true; break;
    case '-v': case '--version': {
      const pkg = JSON.parse(readFileSync(join(PACKAGE_ROOT, 'package.json'), 'utf8'));
      console.log(pkg.version);
      process.exit(0);
    }
    case '-h': case '--help':
      usage();
      process.exit(0);
    default:
      error(`Unknown option: ${arg}`);
      usage();
      process.exit(1);
  }
}

if (flags.claudeOnly && flags.codexOnly) {
  error('--claude-only and --codex-only are mutually exclusive');
  process.exit(1);
}

// ---------------------------------------------------------------------------
// Timestamp & paths
// ---------------------------------------------------------------------------
const now = new Date();
const pad = (n) => String(n).padStart(2, '0');
const TIMESTAMP = `${now.getFullYear()}${pad(now.getMonth() + 1)}${pad(now.getDate())}_${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}`;

const HOME = homedir();
// Same variables Claude Code and Codex read, so a second profile (~/.claude-2) can be targeted.
const CLAUDE_HOME = process.env.CLAUDE_CONFIG_DIR || join(HOME, '.claude');
const CODEX_HOME  = process.env.CODEX_HOME || join(HOME, '.codex');
const AGENTS_HOME = join(HOME, '.agents');
const BACKUP_DIR  = join(HOME, 'just-works-backups', TIMESTAMP);

// ---------------------------------------------------------------------------
// Core operations
// ---------------------------------------------------------------------------
const exists = (p) => { try { lstatSync(p); return true; } catch { return false; } };
const isJunk = (name) => name === '.DS_Store' || name === '__pycache__' || name === '.gitkeep';
const copyFilter = (src) => { const n = src.split(/[\\/]/).pop(); return n !== '.DS_Store' && n !== '__pycache__'; };

// Back up a file, directory or symlink (a symlink is copied as a link, not followed).
function backupTarget(targetPath, backupDir, dryRun) {
  if (!exists(targetPath)) return;
  let relPath = relative(HOME, targetPath);
  // A target outside the home dir keeps its absolute path under the backup dir.
  if (relPath.startsWith('..')) relPath = resolve(targetPath).replace(/^([A-Za-z]:)?[\\/]+/, '');
  const backupPath = join(backupDir, relPath);
  if (dryRun) {
    warn(`Would back up: ${targetPath} -> ${backupPath}`);
  } else {
    mkdirSync(dirname(backupPath), { recursive: true });
    cpSync(targetPath, backupPath, { recursive: true, force: true, verbatimSymlinks: true });
    warn(`Backed up: ${targetPath} -> ${backupPath}`);
  }
}

function backupIfEnabled(targetPath, opts) {
  if (opts.doBackup) backupTarget(targetPath, opts.backupDir, opts.dryRun);
}

function listEntries(dir) {
  return readdirSync(dir).filter((n) => !isJunk(n)).sort();
}

// Install one entry (a file or a whole skill/agent directory). Only the entry itself is
// replaced: a directory entry is replaced as a whole so files removed upstream do not linger,
// and nothing next to it is touched.
function installEntry(src, dest, opts) {
  if (opts.dryRun) {
    if (exists(dest)) {
      backupIfEnabled(dest, opts);
      warn(`Would replace: ${dest}`);
    }
    return;
  }
  backupIfEnabled(dest, opts);
  mkdirSync(dirname(dest), { recursive: true });
  // rmSync on a symlink removes the link, not the directory it points to.
  rmSync(dest, { recursive: true, force: true });
  cpSync(src, dest, { recursive: true, filter: copyFilter });
}

function installFile(srcFile, destFile, label, opts) {
  if (!existsSync(srcFile)) {
    warn(`Source not found, skipping: ${srcFile}`);
    return;
  }
  backupIfEnabled(destFile, opts);
  if (opts.dryRun) {
    info(`Would copy: ${srcFile} -> ${destFile}`);
  } else {
    mkdirSync(dirname(destFile), { recursive: true });
    rmSync(destFile, { force: true });
    copyFileSync(srcFile, destFile);
    info(`Installed: ${label} -> ${destFile}`);
  }
}

// ---------------------------------------------------------------------------
// Manifest: which entries just-works installed into a home directory. Used to remove
// entries that a later version renamed or deleted, without touching other files.
// ---------------------------------------------------------------------------
const MANIFEST_NAME = '.just-works-manifest';

// Entries shipped by earlier versions, used when a home has no manifest yet.
const LEGACY_ENTRIES = {
  claude: ['skills/opus-5-prompting', 'skills/fable-5-prompting', 'skills/gpt-5-6-prompting', 'CLAUDE-CHAT.md', 'agents/diagrammer.md',
    'agents/ticket-creator.md', 'commands/git-sync.md', 'commands/project-docs.md'],
  codex: ['agents/diagrammer.toml', 'agents/ticket-creator.toml', 'prompts/git-sync.md', 'prompts/project-docs.md'],
  agents: ['skills/opus-5-prompting', 'skills/fable-5-prompting', 'skills/gpt-5-6-prompting'],
};

const scopeOf = (entry) => (entry.includes('/') ? entry.split('/')[0] : '.');

// A manifest line must stay inside the home directory.
function entryIsSafe(entry) {
  if (!entry || entry.startsWith('/') || entry.includes('//')) return false;
  return !entry.split('/').some((part) => part === '' || part === '.' || part === '..');
}

class Manifest {
  constructor(home, legacyKey, opts) {
    this.home = home;
    this.path = join(home, MANIFEST_NAME);
    this.opts = opts;
    this.added = new Set();
    this.doneScopes = new Set();
    let raw;
    if (existsSync(this.path)) {
      raw = readFileSync(this.path, 'utf8').split('\n').map((l) => l.trim()).filter((l) => l && !l.startsWith('#'));
    } else {
      raw = LEGACY_ENTRIES[legacyKey];
    }
    this.old = raw.filter((e) => {
      if (entryIsSafe(e)) return true;
      warn(`Ignoring unsafe manifest entry: ${e}`);
      return false;
    });
  }

  // Remove entries of `scope` that an earlier install owned but the current version no longer ships.
  prune(scope, shipped) {
    for (const entry of this.old) {
      if (scopeOf(entry) !== scope) continue;
      const name = scope === '.' ? entry : entry.slice(scope.length + 1);
      if (shipped.includes(name)) continue;
      const target = join(this.home, entry);
      if (!exists(target)) continue;
      backupIfEnabled(target, this.opts);
      if (this.opts.dryRun) {
        warn(`Would prune (no longer shipped): ${target}`);
      } else {
        rmSync(target, { recursive: true, force: true });
        warn(`Pruned (no longer shipped): ${target}`);
      }
    }
  }

  // Install every entry of srcDir into <home>/<scope>/ and prune entries no longer shipped.
  syncScope(scope, srcDir, label) {
    if (!existsSync(srcDir)) {
      warn(`Source not found, skipping: ${srcDir}`);
      return;
    }
    const shipped = listEntries(srcDir);
    this.prune(scope, shipped);
    this.doneScopes.add(scope);
    const destDir = join(this.home, scope);
    for (const name of shipped) {
      installEntry(join(srcDir, name), join(destDir, name), this.opts);
      this.added.add(`${scope}/${name}`);
    }
    info(`${this.opts.dryRun ? 'Would install' : 'Installed'}: ${shipped.length} ${label} entries -> ${destDir}/`);
  }

  // Remove every entry of a scope that just-works no longer ships at all.
  retireScope(scope) {
    this.prune(scope, []);
    this.doneScopes.add(scope);
  }

  // Files owned by just-works directly in the home directory.
  syncOwnedFiles(srcBase, names) {
    this.prune('.', names);
    this.doneScopes.add('.');
    for (const name of names) {
      const src = join(srcBase, name);
      if (!existsSync(src)) {
        warn(`Source not found, skipping: ${src}`);
        continue;
      }
      installFile(src, join(this.home, name), name, this.opts);
      this.added.add(name);
    }
  }

  // Entries installed now, plus old entries of scopes this run skipped.
  save() {
    const all = new Set(this.added);
    for (const entry of this.old) {
      if (!this.doneScopes.has(scopeOf(entry))) all.add(entry);
    }
    if (this.opts.dryRun) {
      info(`Would write manifest: ${this.path}`);
      return;
    }
    mkdirSync(this.home, { recursive: true });
    const tmp = `${this.path}.tmp`;
    writeFileSync(tmp, `# Entries installed by just-works, relative to this directory. Do not add your own files.\n${[...all].sort().join('\n')}\n`);
    renameSync(tmp, this.path);
  }
}

// Codex skills = the Claude skills plus Codex-only extras from .codex/skills.
function stageCodexSkills() {
  const stage = mkdtempSync(join(tmpdir(), 'just-works-skills-'));
  for (const dir of [join(PACKAGE_ROOT, '.claude', 'skills'), join(PACKAGE_ROOT, '.codex', 'skills')]) {
    if (existsSync(dir)) cpSync(dir, stage, { recursive: true, force: true, filter: copyFilter });
  }
  return stage;
}

// rtk >= 0.37 deletes hooks/rtk-rewrite.sh, so a leftover hook entry breaks every Bash call.
// Point those "command" values at `rtk hook claude`, leaving the rest of the file byte-identical.
function migrateRtkHook(settingsPath, opts) {
  if (!existsSync(settingsPath)) return;
  try {
    const text = readFileSync(settingsPath, 'utf8');
    const updated = text.replace(/("command"\s*:\s*)"(?:[^"\\]|\\.)*rtk-rewrite\.sh(?:[^"\\]|\\.)*"/g, '$1"rtk hook claude"');
    if (updated === text) return;
    if (opts.doBackup) backupTarget(settingsPath, opts.backupDir, opts.dryRun);
    if (opts.dryRun) {
      info(`Would migrate: legacy rtk hook -> rtk hook claude in ${settingsPath}`);
    } else {
      writeFileSync(settingsPath, updated);
      info(`Migrated: legacy rtk hook -> rtk hook claude in ${settingsPath}`);
    }
  } catch (err) {
    // An unreadable or read-only (e.g. Nix-managed) file must not abort the rest of the install.
    warn(`Could not migrate legacy rtk hook in ${settingsPath} — set its command to "rtk hook claude" manually (${err.message})`);
  }
}

// ---------------------------------------------------------------------------
// Interactive backup prompt
// ---------------------------------------------------------------------------
function askBackup() {
  return new Promise((resolve) => {
    const rl = createInterface({ input: process.stdin, output: process.stdout });
    rl.question('Do you want to create backups? (Y/n) ', (answer) => {
      rl.close();
      const trimmed = (answer || 'Y').trim();
      resolve(!/^[Nn]/.test(trimmed));
    });
  });
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
async function main() {
  console.log(`${BOLD}just-works installer${NC}\n`);

  // Determine backup behavior
  let doBackup = true;
  if (!flags.dryRun) {
    if (flags.noBackup) {
      doBackup = false;
    } else if (!process.stdin.isTTY) {
      doBackup = true;
      warn('Non-interactive mode detected — backups enabled by default');
    } else {
      doBackup = await askBackup();
    }
    console.log();
  }

  const opts = { backupDir: BACKUP_DIR, doBackup, dryRun: flags.dryRun };

  // --- Claude Code ---
  if (!flags.codexOnly) {
    console.log(`${BOLD}Claude Code${NC}`);
    const claude = new Manifest(CLAUDE_HOME, 'claude', opts);
    claude.syncScope('agents', join(PACKAGE_ROOT, '.claude', 'agents'), 'agent');
    if (!flags.skipSkillsClaude) {
      claude.syncScope('skills', join(PACKAGE_ROOT, '.claude', 'skills'), 'skill');
    } else {
      info('Skipping Claude skills (--skip-skills-claude)');
    }
    claude.retireScope('commands');
    claude.syncScope('output-styles', join(PACKAGE_ROOT, '.claude', 'output-styles'), 'output style');

    if (!flags.skipConfig) {
      if (flags.personal) {
        installFile(join(PACKAGE_ROOT, '.claude', 'settings.json'),         join(CLAUDE_HOME, 'settings.json'), 'settings.json (personal)', opts);
      } else {
        installFile(join(PACKAGE_ROOT, '.claude', 'settings.json.default'), join(CLAUDE_HOME, 'settings.json'), 'settings.json (default)',  opts);
      }
    } else {
      info('Skipping settings.json (--skip-config)');
      migrateRtkHook(join(CLAUDE_HOME, 'settings.json'), opts);
    }

    installFile(join(PACKAGE_ROOT, 'CLAUDE.md'), join(CLAUDE_HOME, 'CLAUDE.md'), 'CLAUDE.md', opts);
    installFile(join(PACKAGE_ROOT, '.claude', 'hooks', 'skill-guard.sh'), join(CLAUDE_HOME, 'hooks', 'skill-guard.sh'), 'hooks/skill-guard.sh', opts);
    claude.syncOwnedFiles(PACKAGE_ROOT, ['web-chat-prompt.md']);
    if (!flags.skipStatusline) {
      installFile(join(PACKAGE_ROOT, '.claude', 'statusline-command.sh'), join(CLAUDE_HOME, 'statusline-command.sh'), 'statusline-command.sh', opts);
    } else {
      info('Skipping statusline-command.sh (--skip-statusline)');
    }
    claude.save();
    console.log();
  }

  // --- Codex ---
  if (!flags.claudeOnly) {
    console.log(`${BOLD}Codex${NC}`);
    const codex = new Manifest(CODEX_HOME, 'codex', opts);
    codex.syncScope('agents', join(PACKAGE_ROOT, '.codex', 'agents'), 'agent');
    codex.retireScope('prompts');
    codex.save();

    if (!flags.skipSkillsCodex) {
      // Codex discovers skills at ~/.agents/skills/ (see AGENTS.md, install.sh).
      const stage = stageCodexSkills();
      try {
        const agents = new Manifest(AGENTS_HOME, 'agents', opts);
        agents.syncScope('skills', stage, 'skill');
        agents.save();
      } finally {
        rmSync(stage, { recursive: true, force: true });
      }
    } else {
      info('Skipping Codex skills (--skip-skills-codex)');
    }

    if (!flags.skipConfig) {
      const azureDir = join(PACKAGE_ROOT, '.codex', 'config', 'azure');
      const configSrc = flags.azure
        ? (flags.personal ? join(azureDir, 'config.toml') : join(azureDir, 'config.toml.default'))
        : (flags.personal ? join(PACKAGE_ROOT, '.codex', 'config.toml') : join(PACKAGE_ROOT, '.codex', 'config.toml.default'));
      const configLabel = `config.toml (${flags.azure ? 'azure, ' : ''}${flags.personal ? 'personal' : 'default'})`;
      installFile(configSrc, join(CODEX_HOME, 'config.toml'), configLabel, opts);

      const hooksSrc = flags.personal
        ? join(PACKAGE_ROOT, '.codex', 'hooks.json')
        : join(PACKAGE_ROOT, '.codex', 'hooks.json.default');
      installFile(hooksSrc, join(CODEX_HOME, 'hooks.json'), `hooks.json (${flags.personal ? 'personal' : 'default'})`, opts);
    } else {
      info('Skipping config.toml and hooks.json (--skip-config)');
    }

    installFile(join(PACKAGE_ROOT, 'AGENTS.md'), join(CODEX_HOME, 'AGENTS.md'), 'AGENTS.md', opts);
    console.log();
  }

  // --- Summary ---
  if (flags.dryRun) {
    console.log(`${YELLOW}Dry run complete — no files were modified.${NC}`);
  } else {
    console.log(`${GREEN}Done.${NC}`);
    if (doBackup) {
      console.log(`  Backups:     ${BACKUP_DIR}/`);
    }
    if (!flags.codexOnly) {
      console.log(`  Claude Code: ${CLAUDE_HOME}/`);
    }
    if (!flags.claudeOnly) {
      console.log(`  Codex:       ${CODEX_HOME}/`);
      console.log(`  Skills:      ${AGENTS_HOME}/skills/`);
    }
  }
}

main().catch((err) => {
  error(err.message);
  process.exit(1);
});
