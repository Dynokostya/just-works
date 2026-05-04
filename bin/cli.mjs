#!/usr/bin/env node

import { readFileSync, existsSync, mkdirSync, cpSync, copyFileSync, rmSync, statSync } from 'node:fs';
import { join, dirname, relative } from 'node:path';
import { homedir } from 'node:os';
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

Install just-works agents, skills, and commands globally.

Options:
  --personal         Use opinionated settings.json (permissions, hooks, sounds)
                     Default: minimal settings.json.default
  --skip-config         Skip installing settings.json
  --skip-statusline     Skip installing statusline-command.sh
  --skip-skills-claude  Skip installing Claude Code skills
  --skip-skills-codex   Skip installing Codex skills
  --claude-only      Install only Claude Code files (~/.claude/)
  --codex-only       Install only Codex files (~/.codex/)
  --dry-run          Show what would be installed without making changes
  --no-backup        Skip backup prompt, disable backups (for CI/non-interactive)
  -v, --version      Print version and exit
  -h, --help         Show this help message

What gets installed:
  ~/.claude/
    agents/       Agent definitions (python-code-writer, prompt-writer)
    skills/       Coding and prompting standards
    commands/     Workflows (project-docs)
    output-styles/  Selectable output styles (compressed, ...)
    settings.json             Permission and hook configuration
    CLAUDE.md                 Global behavioral instructions
    statusline-command.sh     Status line script

  ~/.codex/
    prompts/      Agent definitions (plan-reviewer, project-docs)
    skills/       Coding and prompting standards
    AGENTS.md     Global behavioral instructions`);
}

// ---------------------------------------------------------------------------
// Parse arguments
// ---------------------------------------------------------------------------
const args = process.argv.slice(2);
const flags = {
  personal: false,
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
const CLAUDE_HOME = join(HOME, '.claude');
const CODEX_HOME  = join(HOME, '.codex');
const BACKUP_DIR  = join(HOME, 'just-works-backups', TIMESTAMP);

// ---------------------------------------------------------------------------
// Core operations
// ---------------------------------------------------------------------------
function backupTarget(targetPath, backupDir, dryRun) {
  if (!existsSync(targetPath)) return;
  const relPath = relative(HOME, targetPath);
  const backupPath = join(backupDir, relPath);
  if (dryRun) {
    warn(`Would back up: ${targetPath} -> ${backupPath}`);
  } else {
    mkdirSync(dirname(backupPath), { recursive: true });
    if (statSync(targetPath).isDirectory()) {
      mkdirSync(backupPath, { recursive: true });
      cpSync(targetPath, backupPath, { recursive: true, force: true });
    } else {
      copyFileSync(targetPath, backupPath);
    }
    warn(`Backed up: ${targetPath} -> ${backupPath}`);
  }
}

function cleanTarget(targetPath, dryRun) {
  if (!existsSync(targetPath)) return;
  if (dryRun) {
    warn(`Would remove: ${targetPath}`);
  } else {
    rmSync(targetPath, { recursive: true, force: true });
    warn(`Removed: ${targetPath}`);
  }
}

function prepareTarget(targetPath, backupDir, doBackup, dryRun) {
  if (doBackup) {
    backupTarget(targetPath, backupDir, dryRun);
  } else {
    cleanTarget(targetPath, dryRun);
  }
}

function installDir(srcDir, destDir, label, opts) {
  if (!existsSync(srcDir)) {
    warn(`Source not found, skipping: ${srcDir}`);
    return;
  }
  prepareTarget(destDir, opts.backupDir, opts.doBackup, opts.dryRun);
  if (opts.dryRun) {
    info(`Would copy: ${srcDir}/ -> ${destDir}/`);
  } else {
    mkdirSync(destDir, { recursive: true });
    cpSync(srcDir, destDir, { recursive: true, force: true });
    info(`Installed: ${label} -> ${destDir}/`);
  }
}

function installFile(srcFile, destFile, label, opts) {
  if (!existsSync(srcFile)) {
    warn(`Source not found, skipping: ${srcFile}`);
    return;
  }
  prepareTarget(destFile, opts.backupDir, opts.doBackup, opts.dryRun);
  if (opts.dryRun) {
    info(`Would copy: ${srcFile} -> ${destFile}`);
  } else {
    mkdirSync(dirname(destFile), { recursive: true });
    copyFileSync(srcFile, destFile);
    info(`Installed: ${label} -> ${destFile}`);
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
    installDir(join(PACKAGE_ROOT, '.claude', 'agents'),   join(CLAUDE_HOME, 'agents'),   'agents',   opts);
    if (!flags.skipSkillsClaude) {
      installDir(join(PACKAGE_ROOT, '.claude', 'skills'),  join(CLAUDE_HOME, 'skills'),   'skills',   opts);
    } else {
      info('Skipping Claude skills (--skip-skills-claude)');
    }
    installDir(join(PACKAGE_ROOT, '.claude', 'commands'), join(CLAUDE_HOME, 'commands'), 'commands', opts);
    installDir(join(PACKAGE_ROOT, '.claude', 'output-styles'), join(CLAUDE_HOME, 'output-styles'), 'output-styles', opts);
    if (flags.personal) {
      installDir(join(PACKAGE_ROOT, '.claude', 'hooks'),    join(CLAUDE_HOME, 'hooks'),    'hooks',    opts);
    }

    if (!flags.skipConfig) {
      if (flags.personal) {
        installFile(join(PACKAGE_ROOT, '.claude', 'settings.json'),         join(CLAUDE_HOME, 'settings.json'), 'settings.json (personal)', opts);
      } else {
        installFile(join(PACKAGE_ROOT, '.claude', 'settings.json.default'), join(CLAUDE_HOME, 'settings.json'), 'settings.json (default)',  opts);
      }
    } else {
      info('Skipping settings.json (--skip-config)');
    }

    installFile(join(PACKAGE_ROOT, 'CLAUDE.md'), join(CLAUDE_HOME, 'CLAUDE.md'), 'CLAUDE.md', opts);
    installFile(join(PACKAGE_ROOT, 'CLAUDE-CHAT.md'), join(CLAUDE_HOME, 'CLAUDE-CHAT.md'), 'CLAUDE-CHAT.md', opts);
    if (!flags.skipStatusline) {
      installFile(join(PACKAGE_ROOT, '.claude', 'statusline-command.sh'), join(CLAUDE_HOME, 'statusline-command.sh'), 'statusline-command.sh', opts);
    } else {
      info('Skipping statusline-command.sh (--skip-statusline)');
    }
    console.log();
  }

  // --- Codex ---
  if (!flags.claudeOnly) {
    console.log(`${BOLD}Codex${NC}`);
    installDir(join(PACKAGE_ROOT, '.codex', 'prompts'), join(CODEX_HOME, 'prompts'), 'prompts', opts);
    if (!flags.skipSkillsCodex) {
      installDir(join(PACKAGE_ROOT, '.codex', 'skills'),  join(CODEX_HOME, 'skills'),  'skills',  opts);
    } else {
      info('Skipping Codex skills (--skip-skills-codex)');
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
    }
  }
}

main().catch((err) => {
  error(err.message);
  process.exit(1);
});
