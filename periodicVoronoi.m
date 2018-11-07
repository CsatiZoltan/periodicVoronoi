function [cells, seeds] = periodicVoronoi(domain, varargin)
% Periodic Voronoi tessellation.
%   Inputs:
%       domain: vector of length 4: [bottomleft_x, bottomleft_y, width, height]
%     parameter-value pairs:
%       'seeds', n-by-2 matrix, the x and y coordinates of the seeds
%       'nSeed', 1-by-1 scalar (disregarded is 'seeds' is given)
%   Outputs:
%       cells: m-by-1 cell array, each cell containing a matrix of two columns,
%              the x and y coordinates of a bounded Voronoi cell
%       seeds: n-by-2 matrix, the x and y coordinates of the seeds
%   
%   For the algorithm, see the paper
%       https://link.springer.com/article/10.1007%2Fs00466-008-0339-2
%   
%   Example:
%       1) % Generate 100 cells and then plot them
%          cells = periodicVoronoi([1 2 1 2], 'nSeed',100);
%          for iCell = cells
%              patch(iCell{:}(:,1), iCell{1}(:,2), rand(1,3));
%          end
%          axis('equal'); axis('off');
%       
%       2) % Show the seeds of the Voronoi diagram
%          [cells, seeds] = periodicVoronoi([-1 4 5 3.5], 'nSeed',50);
%          for iCell = cells
%              patch(iCell{:}(:,1), iCell{1}(:,2), rand(1,3));
%          end
%          for iSeed = 1:size(seeds,1)
%              line(seeds(iSeed,1), seeds(iSeed,2), 'Marker','o','MarkerFaceColor','blue');
%          end
%          axis('equal'); axis('off');
%   
%   See also:  voronoi

%   Zoltan Csati
%   07/11/2018


%% Process input
p = inputParser;
p.addRequired('domain', @validateDomain);
p.addParameter('seeds', [], @validateSeeds);
p.addParameter('nSeed', 10, @validateCellCount);
p.parse(domain, varargin{:});
% Extract the values of the parsed inputs
domain = p.Results.domain;
seeds = p.Results.seeds;
nSeed = p.Results.nSeed;
if ~isempty(seeds) % seeds provided by the user
    nSeed = size(seeds,1);
end
domainWithVertices = [domain(1), domain(2); ...
    domain(1)+domain(3), domain(2); ...
    domain(1)+domain(3), domain(2)+domain(4); ...
    domain(1), domain(2)+domain(4)];

%% Create the seeds for the Voronoi cells
if isempty(seeds) % seeds not provided by the user
    seeds = polysample(domainWithVertices, nSeed);
end

%% Replicate the original domain
east = [seeds(:,1)+domain(3), seeds(:,2)];
northeast = [seeds(:,1)+domain(3), seeds(:,2)+domain(4)];
north = [seeds(:,1), seeds(:,2)+domain(4)];
northwest = [seeds(:,1)-domain(3), seeds(:,2)+domain(4)];
west = [seeds(:,1)-domain(3), seeds(:,2)];
southwest = [seeds(:,1)-domain(3), seeds(:,2)-domain(4)];
south = [seeds(:,1), seeds(:,2)-domain(4)];
southeast = [seeds(:,1)+domain(3), seeds(:,2)-domain(4)];

%% Apply the Voronoi tessellation on the extended domain
replica = [east; northeast; north; northwest; west; southwest; south; southeast];
allSeeds = [seeds; replica];
[V, C] = voronoin(allSeeds);
P2.x = domainWithVertices(:,1); P2.y = domainWithVertices(:,2); P2.hole = 0;
nPolygon = numel(C); polygons = cell(1, nPolygon);
for iPolygon = 1:nPolygon
    polygons{iPolygon} = V(C{iPolygon}, :);
end
% Exclude the unbounded Voronoi cells
unbounded = cellfun(@(x) any(any(isinf(x))), polygons);
polygons(unbounded) = [];
nPolygon = numel(polygons);

%% Cut the original domain out of the extended domain
cells = cell(1, nPolygon);
for iPolygon = 1:nPolygon
    P1.x = polygons{iPolygon}(:,1); P1.y = polygons{iPolygon}(:,2); P1.hole = 0;
    P3 = PolygonClip(P1,P2,1); % call external polygon clipping code
    cells{iPolygon} = [P3.x, P3.y];
end
notInOriginal = cellfun(@isempty, cells);
cells(notInOriginal) = [];


end



% Input validating functions
function validateDomain(domain)
   if ~isnumeric(domain)
      error('Domain must have numeric type.');
   end
   if ~isvector(domain) || numel(domain) ~= 4
       error('A vector of length 4 is required.');
   end
   if domain(3) <=0
       error('Domain width must be positive.');
   end
   if domain(4) <=0
       error('Domain height must be positive.');
   end
end

function validateSeeds(seeds)
   if ~isnumeric(seeds)
      error('Seeds must have numeric type.');
   end
   if size(seeds,2) ~= 2
      error('Seeds must be an Nx2 matrix.');
   end
   if size(seeds,1) < 1
      error('At least one seed is required.');
   end
end

function validateCellCount(nCell)
   validateattributes(nCell, {'numeric'}, {'scalar','>=',1,'finite','nonnan','integer'});
end
