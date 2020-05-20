-- Plot Iterator, Author: whoward69; URL: https://forums.civfanatics.com/threads/border-and-area-plot-iterators.474634/
-- Convert funcs odd-r offset to axial. URL: http://www.redblobgames.com/grids/hexagons/
-- Here grid == offset; hex == axial

function ToHexFromGrid(grid)
  local hex = {
      x = grid.x - (grid.y - (grid.y % 2)) / 2;
      y = grid.y;
  }
  return hex
end

function ToGridFromHex(hex_x, hex_y)
  local grid = {
      x = hex_x + (hex_y - (hex_y % 2)) / 2;
      y = hex_y;
  }
  return grid.x, grid.y
end

SECTOR_NONE = nil
SECTOR_NORTH = 1
SECTOR_NORTHEAST = 2
SECTOR_SOUTHEAST = 3
SECTOR_SOUTH = 4
SECTOR_SOUTHWEST = 5
SECTOR_NORTHWEST = 6

DIRECTION_CLOCKWISE = false
DIRECTION_ANTICLOCKWISE = true

DIRECTION_OUTWARDS = false
DIRECTION_INWARDS = true

CENTRE_INCLUDE = true
CENTRE_EXCLUDE = false

function PlotRingIterator(pPlot, r, sector, anticlock)
  -- print(string.format("PlotRingIterator((%i, %i), r=%i, s=%i, d=%s)", pPlot:GetX(), pPlot:GetY(), r, (sector or SECTOR_NORTH), (anticlock and "rev" or "fwd")))
  -- The important thing to remember with hex-coordinates is that x+y+z = 0
  -- So we never actually need to store z as we can always calculate it as -(x+y)
  -- See http://keekerdc.com/2011/03/hexagon-grids-coordinate-systems-and-distance-calculations/

  if (pPlot ~= nil and r > 0) then
      local hex = ToHexFromGrid({x=pPlot:GetX(), y=pPlot:GetY()})
      local x, y = hex.x, hex.y

      -- Along the North edge of the hex (x-r, y+r, z) to (x, y+r, z-r)
      local function north(x, y, r, i) return {x=x-r+i, y=y+r} end
      -- Along the North-East edge (x, y+r, z-r) to (x+r, y, z-r)
      local function northeast(x, y, r, i) return {x=x+i, y=y+r-i} end
      -- Along the South-East edge (x+r, y, z-r) to (x+r, y-r, z)
      local function southeast(x, y, r, i) return {x=x+r, y=y-i} end
      -- Along the South edge (x+r, y-r, z) to (x, y-r, z+r)
      local function south(x, y, r, i) return {x=x+r-i, y=y-r} end
      -- Along the South-West edge (x, y-r, z+r) to (x-r, y, z+r)
      local function southwest(x, y, r, i) return {x=x-i, y=y-r+i} end
      -- Along the North-West edge (x-r, y, z+r) to (x-r, y+r, z)
      local function northwest(x, y, r, i) return {x=x-r, y=y+i} end

      local side = {north, northeast, southeast, south, southwest, northwest}
      if (sector) then
          for i=(anticlock and 1 or 2), sector, 1 do
              table.insert(side, table.remove(side, 1))
          end
      end

      -- This coroutine walks the edges of the hex centered on pPlot at radius r
      local next = coroutine.create(function ()
          if (anticlock) then
              for s=6, 1, -1 do
                  for i=r, 1, -1 do
                      coroutine.yield(side[s](x, y, r, i))
                  end
              end
          else
              for s=1, 6, 1 do
                  for i=0, r-1, 1 do
                      coroutine.yield(side[s](x, y, r, i))
                  end
              end
          end

          return nil
      end)

      -- This function returns the next edge plot in the sequence, ignoring those that fall off the edges of the map
      return function ()
          local pEdgePlot = nil
          local success, hex = coroutine.resume(next)
          -- if (hex ~= nil) then print(string.format("hex(%i, %i, %i)", hex.x, hex.y, -1 * (hex.x+hex.y))) else print("hex(nil)") end

          while (success and hex ~= nil and pEdgePlot == nil) do
              pEdgePlot = Map.GetPlot(ToGridFromHex(hex.x, hex.y))
              if (pEdgePlot == nil) then success, hex = coroutine.resume(next) end
          end

          return success and pEdgePlot or nil
      end
  else
      -- Iterators have to return a function, so return a function that returns nil
      return function () return nil end
  end
end

function PlotAreaSpiralIterator(pPlot, r, sector, anticlock, inwards, centre)
  -- print(string.format("PlotAreaSpiralIterator((%i, %i), r=%i, s=%i, d=%s, w=%s, c=%s)", pPlot:GetX(), pPlot:GetY(), r, (sector or SECTOR_NORTH), (anticlock and "rev" or "fwd"), (inwards and "in" or "out"), (centre and "yes" or "no")))
  -- This coroutine walks each ring in sequence
  local next = coroutine.create(function ()
      if (centre and not inwards) then
          coroutine.yield(pPlot)
      end

      if (inwards) then
          for i=r, 1, -1 do
              for pEdgePlot in PlotRingIterator(pPlot, i, sector, anticlock) do
                  coroutine.yield(pEdgePlot)
              end
          end
      else
          for i=1, r, 1 do
              for pEdgePlot in PlotRingIterator(pPlot, i, sector, anticlock) do
                  coroutine.yield(pEdgePlot)
              end
          end
      end

      if (centre and inwards) then
          coroutine.yield(pPlot)
      end

      return nil
  end)

  -- This function returns the next plot in the sequence
  return function ()
      local success, pAreaPlot = coroutine.resume(next)
      return success and pAreaPlot or nil
  end
end
