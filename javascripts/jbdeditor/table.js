/**
 * TableManager - Table creation and cell/row/column manipulation for JBDEditor
 * Fully WCAG 2.1/2.2 AA compliant with semantic <th scope="col"> and <th scope="row"> headers.
 */
import { createElement } from './utils.js';

export class TableManager {
  /**
   * Generates a fully accessible HTML table element with WCAG scope attributes
   * @param {Object} options
   * @param {number} [options.rows=3]
   * @param {number} [options.cols=3]
   * @param {'row' | 'col' | 'both' | 'none'} [options.headerType='row']
   * @param {boolean} [options.hasHeader=true] Backward compatibility
   * @param {string} [options.caption='']
   * @param {boolean} [options.bordered=true]
   * @returns {HTMLTableElement}
   */
  static createTable({ rows = 3, cols = 3, headerType = null, hasHeader = true, caption = '', bordered = true }) {
    rows = Math.max(1, parseInt(rows, 10) || 3);
    cols = Math.max(1, parseInt(cols, 10) || 3);
    const hType = headerType || (hasHeader ? 'row' : 'none');
    const hasHeaderRow = (hType === 'row' || hType === 'both');
    const hasHeaderCol = (hType === 'col' || hType === 'both');

    const table = createElement('table', {
      className: `jbd-table ${bordered ? 'jbd-table-bordered' : ''}`.trim(),
      style: { width: '100%', borderCollapse: 'collapse' }
    });

    if (caption && caption.trim()) {
      const capEl = createElement('caption', { className: 'jbd-table-caption' }, [caption.trim()]);
      table.appendChild(capEl);
    }

    const tbody = createElement('tbody');

    let bodyRows = rows;
    if (hasHeaderRow) {
      const thead = createElement('thead');
      const headerRow = createElement('tr');
      for (let c = 0; c < cols; c++) {
        const th = createElement('th', { scope: 'col' }, [`Header ${c + 1}`]);
        headerRow.appendChild(th);
      }
      thead.appendChild(headerRow);
      table.appendChild(thead);
      bodyRows = Math.max(1, rows - 1);
    }

    for (let r = 0; r < bodyRows; r++) {
      const tr = createElement('tr');
      for (let c = 0; c < cols; c++) {
        if (c === 0 && hasHeaderCol) {
          const th = createElement('th', { scope: 'row' }, [`Row Header ${r + 1}`]);
          tr.appendChild(th);
        } else {
          const td = createElement('td', {}, [`Cell ${r + 1},${c + 1}`]);
          tr.appendChild(td);
        }
      }
      tbody.appendChild(tr);
    }

    table.appendChild(tbody);
    return table;
  }

  static getActiveCell(container, savedRange = null) {
    const findCellFromNode = (startNode) => {
      if (!startNode) return null;
      let node = startNode.nodeType === Node.TEXT_NODE ? startNode.parentNode : startNode;
      while (node && node !== container && node !== document.body) {
        if (node.tagName === 'TD' || node.tagName === 'TH') {
          return container.contains(node) ? node : null;
        }
        node = node.parentNode;
      }
      return null;
    };

    const selection = window.getSelection();
    if (selection && selection.rangeCount > 0) {
      const cell = findCellFromNode(selection.anchorNode) || findCellFromNode(selection.focusNode);
      if (cell) return cell;
    }

    if (savedRange) {
      const cell = findCellFromNode(savedRange.startContainer) || findCellFromNode(savedRange.commonAncestorContainer);
      if (cell) return cell;
    }

    return null;
  }

  static hasRowHeaders(table) {
    if (!table) return false;
    const firstCells = table.querySelectorAll('tbody tr > :first-child');
    return Array.from(firstCells).some(c => c.tagName === 'TH');
  }

  static focusCell(cell) {
    if (!cell) return;
    try {
      const range = document.createRange();
      range.selectNodeContents(cell);
      range.collapse(true);
      const sel = window.getSelection();
      if (sel) {
        sel.removeAllRanges();
        sel.addRange(range);
      }
    } catch {}
  }

  static addRowAbove(cell) {
    if (!cell) return;
    const row = cell.closest('tr');
    if (!row) return;
    const table = cell.closest('table');
    const isHead = row.parentElement && row.parentElement.tagName === 'THEAD';
    const hasRowHeaders = TableManager.hasRowHeaders(table);

    const newRow = createElement('tr');
    const cols = row.children.length;
    for (let i = 0; i < cols; i++) {
      if (isHead) {
        newRow.appendChild(createElement('th', { scope: 'col' }, ['\u00A0']));
      } else if (i === 0 && hasRowHeaders) {
        newRow.appendChild(createElement('th', { scope: 'row' }, ['\u00A0']));
      } else {
        newRow.appendChild(createElement('td', {}, ['\u00A0']));
      }
    }

    row.parentNode.insertBefore(newRow, row);
    TableManager.focusCell(newRow.children[cell.cellIndex] || newRow.firstElementChild);
  }

  static addRowBelow(cell) {
    if (!cell) return;
    const row = cell.closest('tr');
    if (!row) return;
    const table = cell.closest('table');
    const isHead = row.parentElement && row.parentElement.tagName === 'THEAD';
    const hasRowHeaders = TableManager.hasRowHeaders(table);

    const newRow = createElement('tr');
    const cols = row.children.length;

    if (isHead && table) {
      let tbody = table.querySelector('tbody');
      if (!tbody) {
        tbody = createElement('tbody');
        table.appendChild(tbody);
      }
      for (let i = 0; i < cols; i++) {
        if (i === 0 && hasRowHeaders) {
          newRow.appendChild(createElement('th', { scope: 'row' }, ['\u00A0']));
        } else {
          newRow.appendChild(createElement('td', {}, ['\u00A0']));
        }
      }
      tbody.insertBefore(newRow, tbody.firstChild);
    } else {
      for (let i = 0; i < cols; i++) {
        if (i === 0 && hasRowHeaders) {
          newRow.appendChild(createElement('th', { scope: 'row' }, ['\u00A0']));
        } else {
          newRow.appendChild(createElement('td', {}, ['\u00A0']));
        }
      }
      row.parentNode.insertBefore(newRow, row.nextSibling);
    }
    TableManager.focusCell(newRow.children[cell.cellIndex] || newRow.firstElementChild);
  }

  static addColLeft(cell) {
    if (!cell) return;
    const table = cell.closest('table');
    if (!table) return;

    const colIndex = cell.cellIndex;
    const rows = table.querySelectorAll('tr');

    rows.forEach(r => {
      const isHeaderRow = r.parentElement && r.parentElement.tagName === 'THEAD';
      let newCell;
      if (isHeaderRow) {
        newCell = createElement('th', { scope: 'col' }, ['\u00A0']);
      } else {
        newCell = createElement('td', {}, ['\u00A0']);
      }

      if (colIndex < r.children.length) {
        r.insertBefore(newCell, r.children[colIndex]);
      } else {
        r.appendChild(newCell);
      }
    });
  }

  static addColRight(cell) {
    if (!cell) return;
    const table = cell.closest('table');
    if (!table) return;

    const colIndex = cell.cellIndex;
    const rows = table.querySelectorAll('tr');

    rows.forEach(r => {
      const isHeaderRow = r.parentElement && r.parentElement.tagName === 'THEAD';
      let newCell;
      if (isHeaderRow) {
        newCell = createElement('th', { scope: 'col' }, ['\u00A0']);
      } else {
        newCell = createElement('td', {}, ['\u00A0']);
      }

      const nextCell = r.children[colIndex + 1];
      if (nextCell) {
        r.insertBefore(newCell, nextCell);
      } else {
        r.appendChild(newCell);
      }
    });
  }

  static deleteRow(cell) {
    if (!cell) return;
    const row = cell.closest('tr');
    if (!row) return;
    const table = row.closest('table');
    const nextFocusRow = row.nextElementSibling || row.previousElementSibling;
    const colIdx = cell.cellIndex;
    row.remove();
    if (table) {
      const remainingRows = table.querySelectorAll('tr');
      if (remainingRows.length === 0) {
        table.remove();
      } else if (nextFocusRow) {
        TableManager.focusCell(nextFocusRow.children[Math.min(colIdx, nextFocusRow.children.length - 1)]);
      } else {
        TableManager.focusCell(remainingRows[0].firstElementChild);
      }
    }
  }

  static deleteCol(cell) {
    if (!cell) return;
    const table = cell.closest('table');
    if (!table) return;
    const colIndex = cell.cellIndex;
    const currentRow = cell.closest('tr');

    const rows = table.querySelectorAll('tr');
    rows.forEach(r => {
      if (r.children[colIndex]) {
        r.children[colIndex].remove();
      }
    });

    const firstRow = table.querySelector('tr');
    if (!firstRow || firstRow.children.length === 0) {
      table.remove();
    } else if (currentRow && currentRow.children.length > 0) {
      TableManager.focusCell(currentRow.children[Math.min(colIndex, currentRow.children.length - 1)]);
    }
  }

  static deleteTable(cell) {
    if (!cell) return;
    const table = cell.closest('table');
    if (table) table.remove();
  }
}
