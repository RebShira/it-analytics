for (let row of mytable.rows)
{
    var curr_col = 1;
    for(let cell of row.cells)
    {
       let val = cell.innerText;
       let length = val.length
       if (val.includes('(') && curr_col > 2) {
            cell.style.color = 'red'
       }

       if (val.includes('-') && val.includes('%') && curr_col > 2) {
            cell.style.color = 'red'
       }

       curr_col += 1;
    }
}